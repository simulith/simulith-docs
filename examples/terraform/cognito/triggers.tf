data "archive_file" "post_confirmation" {
  type        = "zip"
  source_file = "${path.module}/trigger-handler.js"
  output_path = "${path.module}/.build/post-confirmation.zip"
}

resource "aws_iam_role" "post_confirmation" {
  name = "${var.pool_name}-post-confirmation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "post_confirmation_logs" {
  name = "logs"
  role = aws_iam_role.post_confirmation.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function" "post_confirmation" {
  function_name    = "${var.pool_name}-post-confirmation"
  role             = aws_iam_role.post_confirmation.arn
  handler          = "trigger-handler.handler"
  runtime          = "nodejs20.x"
  timeout          = 5
  filename         = data.archive_file.post_confirmation.output_path
  source_code_hash = data.archive_file.post_confirmation.output_base64sha256
}

resource "aws_lambda_permission" "cognito_post_confirmation" {
  statement_id  = "AllowCognitoInvokePostConfirmation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}
