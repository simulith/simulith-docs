output "bucket_name" {
  value = aws_s3_bucket.app.id
}

output "function_name" {
  value = aws_lambda_function.processor.function_name
}

output "function_arn" {
  value = aws_lambda_function.processor.arn
}

output "upload_key" {
  value = "in/terraform-demo.txt"
}

output "marker_dir" {
  value = var.marker_dir
}
