output "distribution_id" {
  value = aws_cloudfront_distribution.cdn.id
}

output "distribution_domain_name" {
  value = aws_cloudfront_distribution.cdn.domain_name
}

output "certificate_arn" {
  value = aws_acm_certificate.cdn.arn
}

output "cdn_fqdn" {
  value = local.apex_alias ? aws_route53_record.cdn_apex[0].fqdn : aws_route53_record.cdn_cname[0].fqdn
}

output "zone_id" {
  value = aws_route53_zone.app.zone_id
}
