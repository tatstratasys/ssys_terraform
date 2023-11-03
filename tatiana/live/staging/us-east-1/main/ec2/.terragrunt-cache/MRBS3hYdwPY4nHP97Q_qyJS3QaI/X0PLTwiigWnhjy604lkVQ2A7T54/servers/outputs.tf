output "instance_id" {
  value = aws_instance.server.id
}
output "instance_type" {
  value = aws_instance.server.instance_type
}

output "server_sg_id" {
  value = aws_security_group.server_sg.id
}

output "alb_sg_id" {
  value = aws_security_group.my_alb_sg.id
}

output "lb_dns_name" {
  value = aws_lb.this.dns_name
}

