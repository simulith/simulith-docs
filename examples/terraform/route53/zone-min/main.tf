# Route 53 hosted zone + A/CNAME records — green path on Simulith.
# Web-stack DNS subset (hosted zone + A/CNAME records).
#
#   terraform apply -var-file=terraform.tfvars -parallelism=1
#   terraform destroy -var-file=terraform.tfvars -parallelism=1

resource "aws_route53_zone" "app" {
  name    = var.zone_name
  comment = "${var.project_name} ${var.environment} web zone (Simulith green path)"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.app.zone_id
  name    = "www"
  type    = "A"
  ttl     = 300
  records = [var.www_ipv4]
}

resource "aws_route53_record" "cdn" {
  zone_id = aws_route53_zone.app.zone_id
  name    = "cdn"
  type    = "CNAME"
  ttl     = 300
  records = [var.cdn_target]
}
