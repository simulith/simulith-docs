# API Gateway REST API + Lambda AWS_PROXY + stage — green path on Simulith.
#
#   terraform apply -var-file=terraform.tfvars
#   curl "<invoke_url>"
#   terraform destroy -var-file=terraform.tfvars

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/handler.js"
  output_path = "${path.module}/.build/lambda.zip"
}

resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = "Simulith Terraform green path"
}

resource "aws_api_gateway_resource" "hello" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = var.resource_path
}

resource "aws_api_gateway_method" "hello_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_lambda_function" "hello" {
  function_name = var.function_name
  role          = var.lambda_role_arn
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  timeout       = 3
  memory_size   = 128

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:000000000000:${aws_api_gateway_rest_api.api.id}/*/*"
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.hello.id
  http_method = aws_api_gateway_method.hello_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello.invoke_arn

  depends_on = [aws_lambda_permission.apigw]
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.hello.id,
      aws_api_gateway_method.hello_get.id,
      aws_api_gateway_integration.lambda.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_integration.lambda]
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.stage_name
}
