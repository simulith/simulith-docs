# CloudFront OAC + distribution + Route 53 CNAME — green path on Simulith.
# Web-stack CDN subset (S3 origin + OAC + distribution + DNS CNAME).
#
#   terraform apply -var-file=terraform.tfvars -parallelism=1
#   terraform destroy -var-file=terraform.tfvars -parallelism=1

resource "aws_s3_bucket" "origin" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.origin.id
  key          = "index.html"
  content      = "<html><body>Simulith CDN green path</body></html>"
  content_type = "text/html"
}

resource "aws_cloudfront_origin_access_control" "cdn" {
  name                              = "${var.project_name}-${var.environment}-cdn-oac"
  description                       = "OAC for ${var.project_name} ${var.environment} CDN (Simulith green path)"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = "index.html"
  comment             = "${var.project_name} ${var.environment} CDN (Simulith green path)"

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
    cloudfront_default_certificate = true
  }
}

resource "aws_route53_zone" "app" {
  name    = var.zone_name
  comment = "${var.project_name} ${var.environment} CDN zone (Simulith green path)"
}

resource "aws_route53_record" "cdn" {
  zone_id = aws_route53_zone.app.zone_id
  name    = "cdn"
  type    = "CNAME"
  ttl     = 300
  records = [aws_cloudfront_distribution.cdn.domain_name]
}
