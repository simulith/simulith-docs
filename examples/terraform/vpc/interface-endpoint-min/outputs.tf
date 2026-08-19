output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_id" {
  value = aws_subnet.private.id
}

output "vpc_endpoint_id" {
  value = aws_vpc_endpoint.secretsmanager.id
}

output "vpc_endpoint_dns_entry" {
  value = aws_vpc_endpoint.secretsmanager.dns_entry
}
