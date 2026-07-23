# DynamoDB table + SQS queue — application fan-out (no Streams).
#
#   terraform apply -var-file=terraform.tfvars -parallelism=1
#   terraform destroy -var-file=terraform.tfvars -parallelism=1

resource "aws_dynamodb_table" "events" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"

  attribute {
    name = "Id"
    type = "S"
  }
}

resource "aws_sqs_queue" "fanout" {
  name = var.queue_name
}
