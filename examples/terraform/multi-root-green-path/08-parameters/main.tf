# Production parameters/ root — reads subnets/ + secrets/ + proxydb/ + cognito/ + ses/ remote state (generic demoapp).

resource "aws_ssm_parameter" "store_write" {
  for_each = local.parameter_defs

  name      = "${local.ssm_prefix}/${each.key}"
  type      = each.value.type
  value     = each.value.value
  overwrite = true

  tags = local.common_tags
}
