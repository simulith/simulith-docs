# GetParametersByPath on refresh — validates Terraform data source against Simulith.

data "aws_ssm_parameters_by_path" "store" {
  path      = local.ssm_prefix
  recursive = true

  depends_on = [aws_ssm_parameter.store_write]
}
