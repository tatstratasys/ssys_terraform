
output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "private_subnet_id" {
  value = aws_subnet.private_subnet.id
}

 output "public_subnets_ids" {
  value = [aws_subnet.public_subnet[0].id,aws_subnet.public_subnet[1].id]
 }
output "private_subnet_cidrs" {
  value = aws_subnet.private_subnet.cidr_block
}

output "public_subnet_cidrs" {
  value = [aws_subnet.public_subnet[0].cidr_block, aws_subnet.public_subnet[1].cidr_block]
}

 output "private_availability_zones" {
  value = [aws_subnet.private_subnet.availability_zone]
}
 output "public_availability_zones" {
  value = [aws_subnet.public_subnet[0].availability_zone, aws_subnet.public_subnet[1].availability_zone]
}
