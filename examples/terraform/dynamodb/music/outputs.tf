output "table_name" {
  description = "Created DynamoDB table name"
  value       = aws_dynamodb_table.music.name
}
