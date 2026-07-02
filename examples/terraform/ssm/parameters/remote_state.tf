# Prod-shaped remote state reads (same keys as Loyaleasy AWS stacks).
# Disabled when use_remote_state = false (Simulith local green path).

data "terraform_remote_state" "proxydb" {
  count   = var.use_remote_state ? 1 : 0
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state"
    key    = "${var.project_name}-proxy-state"
    region = var.aws_region
  }
}

data "terraform_remote_state" "subnets" {
  count   = var.use_remote_state ? 1 : 0
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state"
    key    = "${var.project_name}-subnets-state"
    region = var.aws_region
  }
}

data "terraform_remote_state" "secrets" {
  count   = var.use_remote_state ? 1 : 0
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state"
    key    = "${var.project_name}-secrets-state"
    region = var.aws_region
  }
}

data "terraform_remote_state" "cognito" {
  count   = var.use_remote_state ? 1 : 0
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state"
    key    = "${var.project_name}-cognito-state"
    region = var.aws_region
  }
}

data "terraform_remote_state" "ses" {
  count   = var.use_remote_state ? 1 : 0
  backend = "s3"
  config = {
    bucket = "${var.project_name}-terraform-state"
    key    = "${var.project_name}-ses-state"
    region = var.aws_region
  }
}
