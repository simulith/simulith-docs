output "s3_bucket_id" {
  value = aws_s3_bucket.remote_state.id
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.remote_state.arn
}

output "dynamodb_table_id" {
  value = aws_dynamodb_table.remote_state_lock.id
}

output "dynamodb_table_arn" {
  value = aws_dynamodb_table.remote_state_lock.arn
}
