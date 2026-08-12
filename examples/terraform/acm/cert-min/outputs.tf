output "zone_id" {
  value = aws_route53_zone.app.zone_id
}

output "certificate_arn" {
  value = aws_acm_certificate_validation.app.certificate_arn
}

output "domain_name" {
  value = aws_acm_certificate.app.domain_name
}
