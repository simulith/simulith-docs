output "rds_proxy_role_arn" {
  value = aws_iam_role.proxy.arn
}

output "rds_proxy_policy_arn" {
  value = aws_iam_policy.rds_proxy.arn
}
