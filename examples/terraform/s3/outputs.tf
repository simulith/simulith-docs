output "bucket_name" {
  value = aws_s3_bucket.app.id
}

output "config_key" {
  value = aws_s3_object.config.key
}

output "readme_key" {
  value = aws_s3_object.readme.key
}
