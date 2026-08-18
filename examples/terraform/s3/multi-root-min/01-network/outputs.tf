output "vpc_id" {
  description = "VPC ID for terraform_remote_state consumers."
  value       = aws_vpc.vpc.id
}

output "vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}
