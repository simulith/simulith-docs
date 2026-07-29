# EventBridge rate rule → Lambda — green path on Simulith (SML-173).

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/handler.js"
  output_path = "${path.module}/.build/lambda.zip"
}

resource "aws_lambda_function" "demo" {
  function_name = var.function_name
  role          = var.lambda_role_arn
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  timeout       = 3
  memory_size   = 128

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = var.rule_name
  schedule_expression = "rate(1 minute)"
  state               = "ENABLED"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "lambda"
  arn       = aws_lambda_function.demo.arn
}
