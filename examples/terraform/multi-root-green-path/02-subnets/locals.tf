locals {
  environment = var.environment
  name_prefix = "${var.project_name}-${local.environment}"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
}
