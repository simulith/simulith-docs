# CloudWatch Logs log group — green path on Simulith.
#
#   terraform apply -var-file=terraform.tfvars -parallelism=1
#   terraform destroy -var-file=terraform.tfvars -parallelism=1

resource "aws_cloudwatch_log_group" "app" {
  name = var.log_group_name
}
