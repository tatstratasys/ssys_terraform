
resource "aws_acm_certificate" "tls_certificate" {
  domain_name               = var.domain_name
  #subject_alternative_names = ["*.tatiana.grabcad.net"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# validate acm certificates
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.tls_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.route53_record: record.fqdn]
}


data "aws_route53_zone" "route53_zone" {
  name         = var.aws_route53_zone_name
  private_zone = false
}


# create a record set in route 53 for domain validatation
resource "aws_route53_record" "route53_record" {
  for_each = {
    for record in aws_acm_certificate.tls_certificate.domain_validation_options : record.domain_name => {
      name   = record.resource_record_name
      record = record.resource_record_value
      type   = record.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.route53_zone.id
}

