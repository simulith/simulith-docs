output "ssm_prefix" {
  value = local.ssm_prefix
}

output "parameter_names" {
  value = [for k in sort(keys(local.parameter_defs)) : "${local.ssm_prefix}/${k}"]
}

output "parameter_count" {
  value = length(local.parameter_defs)
}

output "parameters_by_path_names" {
  description = "Names under ssm_prefix from GetParametersByPath (Terraform refresh)"
  value       = data.aws_ssm_parameters_by_path.store.names
}

output "parameters_by_path_count" {
  description = "Count from GetParametersByPath — should match parameter_count after apply"
  value       = length(data.aws_ssm_parameters_by_path.store.names)
}
