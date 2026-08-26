locals {
  environment = var.environment
  name_prefix = "${var.project_name}-${local.environment}"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  vpc_cidr    = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
  subnet_ids = [
    data.terraform_remote_state.subnets.outputs.database_subnet_1_id,
    data.terraform_remote_state.subnets.outputs.database_subnet_2_id,
    data.terraform_remote_state.subnets.outputs.database_subnet_3_id,
  ]
}
