# S3 bucket + object — green path on Simulith (CreateBucket + PutObject + HeadObject + DeleteObject + DeleteBucket).
#
#   terraform apply -var-file=terraform.tfvars
#   terraform destroy -var-file=terraform.tfvars

resource "aws_s3_bucket" "app" {
  bucket = var.bucket_name

  # force_destroy removes all objects before deleting the bucket on terraform destroy.
  force_destroy = true
}

resource "aws_s3_object" "config" {
  bucket       = aws_s3_bucket.app.id
  key          = "config/app.json"
  content      = jsonencode({ environment = "local", service = "simulith", managed_by = "terraform" })
  content_type = "application/json"
}

resource "aws_s3_object" "readme" {
  bucket       = aws_s3_bucket.app.id
  key          = "docs/README.md"
  content      = "# App assets — managed by Terraform on Simulith\n"
  content_type = "text/markdown"
}
