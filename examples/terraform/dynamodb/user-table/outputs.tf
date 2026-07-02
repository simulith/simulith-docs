output "table_name" {
  description = "Created user table name"
  value       = aws_dynamodb_table.user.name
}

output "table_arn" {
  description = "Table ARN"
  value       = aws_dynamodb_table.user.arn
}

output "gsi_program_cognito_index" {
  description = "GSI name — lookup users by program (programId + cognito_sub)"
  value       = "programId-cognito_sub-index"
}

output "gsi_program_type_number_index" {
  description = "GSI name — lookup by program + document (programId + typeNumber)"
  value       = "programId-typeNumber-index"
}
