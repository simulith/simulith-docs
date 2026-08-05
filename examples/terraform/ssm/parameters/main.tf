# Simulith-compatible SSM parameter store example (Cloud Posse pattern).
# https://docs.cloudposse.com/modules/library/aws/ssm-parameter-store/
#
# terraform plan  -var-file=dev.tfvars
# terraform apply -var-file=dev.tfvars -parallelism=1
#
# Native aws_ssm_parameter + for_each instead of cloudposse/ssm-parameter-store/aws
# so custom Simulith endpoint works without module-specific behavior.

resource "aws_ssm_parameter" "store_write" {
  for_each = local.parameter_defs

  name      = "${local.ssm_prefix}/${each.key}"
  type      = each.value.type
  value     = each.value.value
  overwrite = true

  tags = local.common_tags
}
