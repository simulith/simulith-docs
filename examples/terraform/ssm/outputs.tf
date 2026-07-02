output "service_name" {
  description = "Terraform-managed parameter name"
  value       = aws_ssm_parameter.service_name.name
}

output "log_level" {
  description = "Terraform-managed parameter name"
  value       = aws_ssm_parameter.log_level.name
}

output "log_level_value" {
  description = "Value of /app/tf-demo/log-level"
  value       = aws_ssm_parameter.log_level.value
  sensitive   = true
}
