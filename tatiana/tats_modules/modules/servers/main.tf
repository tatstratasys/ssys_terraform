
resource "aws_key_pair" "keypair" {
  key_name   = "ngalim_pub_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCcfh+QmIzWfKM6Vo9j6rDzNZnjfhC48s3gUQs4O22MyVtkT40/Gpy71ddjAyllVJo1idYL5bl+PpGwAT43axHpYA+1HbULkfMsYV7AW+Rl4AIhdOcDUTDYAZcXw2kwm9zB5/Xufg2Hv6w51ydPQ2uC5TR0f/jlizCeXMcZocsZWvfL2JKsTqx6uA+SWS2nDY3w8kgdBhKCgaPvMdbLSAAa3x2Kfv5iByBvmy4uEVr3IYZnP8tY5bLs5Mf6wfRpoafaQDK5wcIuo8amrBw1gNN2zYCZTI4XI4nqUiiE8xxtLx2jBFRppQPBIzj2PtKHOwcf1SQgaZljtcZyKKt3kynt rsa-key-20231004"
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
 resource "aws_iam_role_policy_attachment" "ec2_s3_policy" {
  role       = aws_iam_role.ec2_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}


resource "aws_instance" "server" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnet_id[0]
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
yum install -y git
yum install -y python3
sudo yum install -y python-pip
sudo python3 -m pip install -r requirements.txt
git clone https://github.com/tatstratasys/test-app.git .
echo "Testing my server" | sudo tee /var/www/html/index.html
rm /var/www/html/index.html
cd /var/www/html
chmod 755 ./*
sudo python3 api.py
EOF
}

resource "aws_security_group" "server_sg" {
  name        = "server_sg"
  description = "Allow web inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.my_alb_sg.id]
  }

   ingress {
    description     = "HTTP"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.my_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "my_alb_sg" {
  name        = "my_alb-security-group"
  description = "Security group for the internet-facing ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port   = 9000
    to_port     = 9000
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

resource "aws_lb" "this" {
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_alb_sg.id]
  subnets            = var.public_subnets_ids
 # enable_deletion_protection = true
 
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-alb-target-group"
  protocol = "HTTP"
  port     = 80
  vpc_id   = var.vpc_id
}


resource "aws_lb_target_group_attachment" "tg_attach" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_instance.server.id
  port             = 80
}

resource "aws_lb_listener_certificate" "listener_cert" {
  listener_arn    = aws_lb_listener.listener_443.arn
  certificate_arn = var.acm_certificate_arn
}


resource "aws_lb_listener" "listener_80" {
  load_balancer_arn = aws_lb.this.arn
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

resource "aws_lb_listener" "listener_9000" {
  load_balancer_arn = aws_lb.this.arn
  port              = "9000"
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
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
 }

data "aws_route53_zone" "route53_zone" {
  name         = var.aws_route53_zone_name
  private_zone = false
}

data "aws_lb_hosted_zone_id" "this" {
}


resource "aws_route53_record" "my_app" {
  zone_id = data.aws_route53_zone.route53_zone.id
  name    = var.aws_route53_record
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = data.aws_lb_hosted_zone_id.this.id
    evaluate_target_health = true
  }
}



