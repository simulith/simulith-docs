output "topic_arn" {
  description = "SNS topic ARN (CloudWatch alarm actions, remote state)."
  value       = aws_sns_topic.alarms.arn
}

output "topic_name" {
  description = "SNS topic name."
  value       = aws_sns_topic.alarms.name
}

output "subscription_arn" {
  description = "SQS protocol subscription ARN."
  value       = aws_sns_topic_subscription.alarm_to_sqs.arn
}

output "queue_arn" {
  description = "Fan-out SQS queue ARN."
  value       = aws_sqs_queue.alarm_fanout.arn
}

output "queue_url" {
  description = "Fan-out SQS queue URL."
  value       = aws_sqs_queue.alarm_fanout.url
}
