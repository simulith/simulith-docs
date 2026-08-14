# CloudFront web prod subset — S3 + OAC + ACM viewer cert + Route 53 — green path on Simulith.
# Combines cert-min (zone + ACM + validation) with cdn-min (S3 + OAC + distribution + CNAME).
#
#   terraform apply -var-file=terraform.tfvars -parallelism=1
#   terraform destroy -var-file=terraform.tfvars -parallelism=1

resource "aws_route53_zone" "app" {
  name    = var.zone_name
  comment = "${var.project_name} ${var.environment} web prod zone (Simulith green path)"
}

resource "aws_acm_certificate" "cdn" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for option in aws_acm_certificate.cdn.domain_validation_options : option.domain_name => {
      name   = option.resource_record_name
      record = option.resource_record_value
      type   = option.resource_record_type
    }
  }

  allow_overwrite = true
  zone_id         = aws_route53_zone.app.zone_id
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
}

resource "aws_acm_certificate_validation" "cdn" {
  certificate_arn         = aws_acm_certificate.cdn.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_s3_bucket" "origin" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.origin.id
  key          = "index.html"
  content      = "<html><body>Simulith web prod green path</body></html>"
  content_type = "text/html"
}

resource "aws_cloudfront_origin_access_control" "cdn" {
  name                              = "${var.project_name}-${var.environment}-web-oac"
  description                       = "OAC for ${var.project_name} ${var.environment} web prod (Simulith green path)"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "${var.project_name} ${var.environment} web prod CDN (Simulith green path)"
  aliases             = [var.domain_name]

  origin {
    domain_name              = aws_s3_bucket.origin.bucket_regional_domain_name
    origin_id                = "s3-origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.cdn.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cdn.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [aws_acm_certificate_validation.cdn]
}

resource "aws_route53_record" "cdn" {
  zone_id = aws_route53_zone.app.zone_id
  name    = trimsuffix(replace(var.domain_name, ".${var.zone_name}", ""), ".")
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.cdn.domain_name]
}
