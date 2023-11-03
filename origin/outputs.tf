output "certificate_arn" {
  value = aws_acm_certificate.tls_certificate.arn
}

output "alb_dns_name" {
  value = aws_lb.my_alb.dns_name

}