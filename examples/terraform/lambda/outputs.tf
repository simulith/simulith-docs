output "function_name" {
  value = aws_lambda_function.worker.function_name
}

output "function_arn" {
  value = aws_lambda_function.worker.arn
}

output "queue_url" {
  value = aws_sqs_queue.worker.url
}

output "queue_arn" {
  value = aws_sqs_queue.worker.arn
}

output "event_source_mapping_uuid" {
  value = aws_lambda_event_source_mapping.worker.uuid
}
