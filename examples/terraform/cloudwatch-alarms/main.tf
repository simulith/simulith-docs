# CloudWatch metric alarm — green path on Simulith.
#
#   terraform apply -var-file=terraform.tfvars -parallelism=1
#   terraform destroy -var-file=terraform.tfvars -parallelism=1

resource "aws_cloudwatch_metric_alarm" "demo" {
  alarm_name          = var.alarm_name
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = var.metric_name
  namespace           = var.metric_namespace
  period              = 300
  statistic           = "Average"
  threshold           = var.threshold
}
