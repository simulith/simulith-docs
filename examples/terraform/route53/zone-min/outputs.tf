output "zone_id" {
  value = aws_route53_zone.app.zone_id
}

output "zone_name_servers" {
  value = aws_route53_zone.app.name_servers
}

output "www_fqdn" {
  value = aws_route53_record.www.fqdn
}
