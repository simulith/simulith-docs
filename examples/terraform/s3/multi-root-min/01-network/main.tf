# Downstream network root: VPC only. Remote-state pattern, not full network-min.

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-VPC"
    Environment = var.environment
  }
}
