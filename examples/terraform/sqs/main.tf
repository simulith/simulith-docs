# SQS standard queue — green path on Simulith (CreateQueue + GetQueueAttributes + DeleteQueue).
#
#   terraform apply -var-file=terraform.tfvars
#   terraform destroy -var-file=terraform.tfvars

resource "aws_sqs_queue" "app" {
  name = var.queue_name
}
