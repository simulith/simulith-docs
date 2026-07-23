# Lambda function + SQS event source mapping — green path on Simulith.
#
#   terraform apply -var-file=terraform.tfvars
#   terraform destroy -var-file=terraform.tfvars

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/handler.js"
  output_path = "${path.module}/.build/lambda.zip"
}

resource "aws_sqs_queue" "worker" {
  name = var.queue_name
}

resource "aws_lambda_function" "worker" {
  function_name = var.function_name
  role          = var.lambda_role_arn
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  timeout       = 3
  memory_size   = 128

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = var.environment_variables
  }
}

resource "aws_lambda_event_source_mapping" "worker" {
  event_source_arn = aws_sqs_queue.worker.arn
  function_name    = aws_lambda_function.worker.arn
  batch_size       = 10
  enabled          = true
}
