output "table_name" {
  value = aws_dynamodb_table.events.name
}

output "table_arn" {
  value = aws_dynamodb_table.events.arn
}

output "queue_name" {
  value = aws_sqs_queue.fanout.name
}

output "queue_url" {
  value = aws_sqs_queue.fanout.url
}

output "queue_arn" {
  value = aws_sqs_queue.fanout.arn
}
