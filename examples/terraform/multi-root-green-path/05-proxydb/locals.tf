locals {
  environment = var.environment
  name_prefix = "${var.project_name}-${local.environment}"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  vpc_cidr    = data.terraform_remote_state.vpc.outputs.vpc_cidr_block
  proxy_subnet_ids = [
    data.terraform_remote_state.subnets.outputs.database_subnet_4_id,
    data.terraform_remote_state.subnets.outputs.database_subnet_5_id,
    data.terraform_remote_state.subnets.outputs.database_subnet_6_id,
  ]
  secret_arn  = data.terraform_remote_state.secrets.outputs.secret_arn
  kms_key_arn = data.terraform_remote_state.secrets.outputs.kms_key_arn
  db_instance_identifier = local.name_prefix
}
