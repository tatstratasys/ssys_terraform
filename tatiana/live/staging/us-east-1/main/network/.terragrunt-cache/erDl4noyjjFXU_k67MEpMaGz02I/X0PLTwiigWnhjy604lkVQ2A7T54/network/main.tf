
resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.env}-vpc"
  }
}

# data "aws_vpc" "this" {
#   id = aws_vpc.this.id
#   tags = {
#     Name = "${var.env}-vpc"
#   }
# }

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "private_subnet" {
  #count = 1
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, 4)
  availability_zone = element(data.aws_availability_zones.available.names, 0)

  tags = {
    Name = "private_subnet"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = element(data.aws_availability_zones.available.names, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.env}-gw"
  }
}

resource "aws_nat_gateway" "this" {
  subnet_id     = aws_subnet.public_subnet[0].id
  allocation_id = aws_eip.nat_eip.id
  depends_on    = [aws_internet_gateway.this]

  tags = {
    Name = "${var.env}-natgw"
  }
}

resource "aws_eip" "nat_eip" {
  #instance = aws_nat_gateway.my_natgw.id
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table" "nat_route_table" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.this.id
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

