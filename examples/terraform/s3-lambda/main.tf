# S3 bucket + Lambda + bucket notification — S3 ObjectCreated → async invoke.
#
#   terraform apply -var-file=terraform.tfvars -parallelism=1
#   terraform destroy -var-file=terraform.tfvars -parallelism=1

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/handler.js"
  output_path = "${path.module}/.build/lambda.zip"
}

resource "aws_s3_bucket" "app" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_lambda_function" "processor" {
  function_name = var.function_name
  role          = var.lambda_role_arn
  handler       = "handler.handler"
  runtime       = "nodejs20.x"
  timeout       = 5
  memory_size   = 128

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      MARKER_DIR = var.marker_dir
    }
  }
}

resource "aws_s3_bucket_notification" "object_created" {
  bucket = aws_s3_bucket.app.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "in/"
    id                  = "s3-object-created-tf"
  }

  depends_on = [aws_lambda_function.processor]
}
