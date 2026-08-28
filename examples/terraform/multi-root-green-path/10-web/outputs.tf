output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.cdn.id
}

output "distribution_domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "certificate_arn" {
  description = "ACM viewer certificate ARN"
  value       = aws_acm_certificate.cdn.arn
}

output "cdn_fqdn" {
  description = "Route 53 record FQDN for the CDN alias"
  value       = local.apex_alias ? aws_route53_record.cdn_apex[0].fqdn : aws_route53_record.cdn_cname[0].fqdn
}

output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.app.zone_id
}
