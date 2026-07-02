output "ssm_prefix" {
  value = local.ssm_prefix
}

output "parameter_names" {
  value = [for k in sort(keys(local.parameter_defs)) : "${local.ssm_prefix}/${k}"]
}

output "parameter_count" {
  value = length(local.parameter_defs)
}
