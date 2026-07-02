output "queue_name" {
  value = aws_sqs_queue.app.name
}

output "queue_url" {
  value = aws_sqs_queue.app.url
}
