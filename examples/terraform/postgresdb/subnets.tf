# Three RDS subnets — production postgresdb/ uses database_subnet_1–3 from subnets/ remote state.

resource "aws_subnet" "database_subnet_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.name_prefix}-database-subnet-1"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "rds-postgres-public"
  }
}

resource "aws_subnet" "database_subnet_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.name_prefix}-database-subnet-2"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "rds-postgres-public"
  }
}

resource "aws_subnet" "database_subnet_3" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.name_prefix}-database-subnet-3"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "rds-postgres-public"
  }
}
