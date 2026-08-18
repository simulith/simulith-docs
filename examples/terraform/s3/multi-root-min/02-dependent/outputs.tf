output "security_group_id" {
  value = aws_security_group.app.id
}

output "vpc_id" {
  value = data.terraform_remote_state.network.outputs.vpc_id
}
