# GetParametersByPath on refresh — validates Terraform data source against Simulith (SML-030).
# After apply, names under local.ssm_prefix should match aws_ssm_parameter.store_write.

data "aws_ssm_parameters_by_path" "store" {
  path      = local.ssm_prefix
  recursive = true
}
