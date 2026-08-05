# Minimum Postgres RDS layout on Simulith.
# Includes embedded VPC/subnet/SG (same shape as vpc/network-min) plus RDS resources.

locals {
  environment = var.environment
  name_prefix = "${var.project_name}-${local.environment}"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${local.name_prefix}-VPC"
    Environment = local.environment
  }
}

resource "aws_subnet" "database_subnet_1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${local.name_prefix}-database-subnet-1"
  }
}

resource "aws_subnet" "database_subnet_2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "${local.name_prefix}-database-subnet-2"
  }
}

resource "aws_security_group" "database_security_group" {
  name        = "${local.name_prefix}-database-sg"
  description = "Security group for PostgreSQL database"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "PostgreSQL access from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-database-sg"
  }
}

resource "aws_db_subnet_group" "subnet" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [aws_subnet.database_subnet_1.id, aws_subnet.database_subnet_2.id]
  description = "Subnet group for ${var.project_name} PostgreSQL database"
}

resource "aws_db_parameter_group" "postgres_params" {
  name   = "${local.name_prefix}-postgres-params"
  family = "postgres15"

  parameter {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  }
}

resource "aws_db_instance" "postgres_db" {
  identifier     = local.name_prefix
  engine         = "postgres"
  engine_version = "15.13"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.project_name
  username = var.user_database
  password = var.password_database

  db_subnet_group_name   = aws_db_subnet_group.subnet.name
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  parameter_group_name   = aws_db_parameter_group.postgres_params.name
  publicly_accessible    = false
  port                   = 5432

  skip_final_snapshot = true
}
