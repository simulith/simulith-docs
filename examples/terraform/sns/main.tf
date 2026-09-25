# SNS topic + SQS subscription — green path on Simulith.
#
#   terraform apply -var-file=terraform.tfvars -auto-approve
#   terraform destroy -var-file=terraform.tfvars -auto-approve

resource "aws_sns_topic" "alarms" {
  name = local.topic_name
}

resource "aws_sqs_queue" "alarm_fanout" {
  name = local.queue_name
}

resource "aws_sns_topic_subscription" "alarm_to_sqs" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.alarm_fanout.arn
}
