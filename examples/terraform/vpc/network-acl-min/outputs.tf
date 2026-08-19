output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_id" {
  value = aws_subnet.public.id
}

output "network_acl_id" {
  value = aws_network_acl.this.id
}
