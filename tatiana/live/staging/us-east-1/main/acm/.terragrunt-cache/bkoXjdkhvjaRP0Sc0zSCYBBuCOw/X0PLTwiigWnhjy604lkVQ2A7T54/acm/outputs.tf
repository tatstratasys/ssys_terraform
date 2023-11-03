output "acm_certificate_arn" {
  value = aws_acm_certificate.tls_certificate.arn
}

output "aws_acm_certificate" {
  value     = aws_acm_certificate.tls_certificate
  sensitive = true
}

output "aws_route53_fqdns" {
  value = [for record in aws_route53_record.route53_record : record.fqdn]
}

output "aws_route53_zone_name" {
  value = data.aws_route53_zone.route53_zone
}   