
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my_vpc"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_subnet"
  }
}

resource "aws_subnet" "public_subnet" {
  count             = 2
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = element(["10.0.2.0/24", "10.0.3.0/24"], count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "gw"
  }
}

resource "aws_nat_gateway" "my_natgw" {
  subnet_id     = aws_subnet.public_subnet[0].id
  allocation_id = aws_eip.nat_eip.id
  depends_on    = [aws_internet_gateway.gw]

  tags = {
    Name = "natgw"
  }
}

resource "aws_eip" "nat_eip" {
  #instance = aws_nat_gateway.my_natgw.id
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table" "nat_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my_natgw.id
  }
}

resource "aws_route_table_association" "rta" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.nat_route_table.id
}

resource "aws_route_table_association" "rtb" {
  subnet_id      = aws_subnet.public_subnet[0].id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_route_table_association" "rtc" {
  subnet_id      = aws_subnet.public_subnet[1].id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_security_group" "server_sg" {
  name        = "server_sg"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.my_alb_sg[0].id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "keypair" {
  key_name   = "ngalim_pub_key"
  public_key = file("./ngalim_pub_key")
}

resource "aws_iam_instance_profile" "ec2_iam_profile2" {
  name = "ec2_iam_profile2"
  role = aws_iam_role.ec2_iam_role.name
}

resource "aws_iam_role" "ec2_iam_role" {
  name               = "ec2_iam_role"
  path               = "/"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {
      "Service": "ec2.amazonaws.com"
    },
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_role_policy_attachment" "ec2-ssm-policy" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_instance" "server" {
  ami                         = var.ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private_subnet.id
  security_groups             = [aws_security_group.server_sg.id]
  key_name                    = aws_key_pair.keypair.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_iam_profile2.name
  associate_public_ip_address = false

  tags = {
    Name = "my-private-server"
  }

  user_data = <<EOF
#!/bin/sh
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Testing my server" | sudo tee /var/www/html/index.html
EOF            
}


resource "aws_security_group" "my_alb_sg" {
  count       = 1
  name        = "my_alb-security-group"
  description = "Security group for the internet-facing ALB"
  vpc_id      = aws_vpc.my_vpc.id


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]

  }
}


resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_alb_sg[0].id]
  subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]
  # enable_deletion_protection = true

  depends_on = [aws_acm_certificate.certificate]
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-alb-target-group"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id
}


resource "aws_lb_target_group_attachment" "tg_attach" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.server.id
  port             = 80
}


resource "aws_lb_listener" "listener_80" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"
 
   default_action {
     type = "redirect"

     redirect {
       port = "443"
       protocol = "HTTPS"
       status_code = "HTTP_301"
     }
   }
 }

resource "aws_lb_listener" "listener_443" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.tls_cert.arn
  

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
 }

#  resource "aws_lb_listener_rule" "listener_rule" {
#    listener_arn = aws_lb_listener.listener_443.arn
#    priority = 100

#    action {
#      type = "forward"
#      target_group_arn = aws_lb_target_group.my_target_group.arn
#    }
#     condition {
#     http_header {
#       http_header_name = "X-Forwarded-For"
#       values           = ["0.0.0.0/0"]
#     }
#     }
#   }
 

resource "aws_lb_listener_certificate" "listener_cert" {
  listener_arn    = aws_lb_listener.listener_443.arn
  certificate_arn = aws_acm_certificate.tls_certificate.arn
}


resource "aws_acm_certificate" "tls_certificate" {
  domain_name               = "tatiana.grabcad.net"
  subject_alternative_names = ["*.tatiana.grabcad.net"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "route53_zone" {
  name         = "tatiana.grabcad.net"
  private_zone = false
}

data "aws_lb_hosted_zone_id" "this" {

}


resource "aws_route53_record" "my_app" {
  zone_id = data.aws_route53_zone.route53_zone.id
  name    = "myapp.tatiana.grabcad.net"
  type    = "A"

  alias {
    name                   = aws_lb.my_alb.dns_name
     zone_id                = data.aws_lb_hosted_zone_id.this.id
    evaluate_target_health = true
  }
}


# create a record set in route 53 for domain validatation
resource "aws_route53_record" "route53_record" {
  for_each = {
    for xyz in aws_acm_certificate.tls_certificate.domain_validation_options : xyz.domain_name => {
      name   = xyz.resource_record_name
      record = xyz.resource_record_value
      type   = xyz.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.route53_zone.id
}

# validate acm certificates
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.tls_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.route53_record : record.fqdn]
}