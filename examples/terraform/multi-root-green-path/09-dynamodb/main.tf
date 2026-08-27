# User table — same shape as production dynamodb/ root and single-root twin
# runtime/examples/terraform/dynamodb/user-table/
resource "aws_dynamodb_table" "user" {
  name         = local.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "cognito_sub"

  attribute {
    name = "cognito_sub"
    type = "S"
  }

  attribute {
    name = "programId"
    type = "S"
  }

  attribute {
    name = "typeNumber"
    type = "S"
  }

  global_secondary_index {
    name            = "programId-cognito_sub-index"
    hash_key        = "programId"
    range_key       = "cognito_sub"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "programId-typeNumber-index"
    hash_key        = "programId"
    range_key       = "typeNumber"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = local.is_prod
  }

  deletion_protection_enabled = local.is_prod

  tags = {
    Name        = "${var.project_name}-user"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "user-data-cognito-sync"
  }
}
