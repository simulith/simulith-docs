output "rest_api_id" {
  value = aws_api_gateway_rest_api.api.id
}

output "invoke_url" {
  description = "Stage HTTP invoke URL (Simulith _user_request_ path; no SigV4)"
  value       = "${var.simulith_endpoint}/restapis/${aws_api_gateway_rest_api.api.id}/${aws_api_gateway_stage.stage.stage_name}/_user_request_/${var.resource_path}"
}

output "function_name" {
  value = aws_lambda_function.hello.function_name
}
