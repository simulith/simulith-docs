# Production postgresdb/ root pattern — RDS Postgres + SG + subnet/parameter groups (generic demoapp).

resource "aws_security_group" "database_security_group" {
  name        = "${local.name_prefix}-database-sg"
  description = "Security group for PostgreSQL database - allows access from VPC only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL access from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${local.name_prefix}-database-sg"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "postgres-database-access"
  }
}

resource "aws_db_subnet_group" "subnet" {
  name        = "${local.name_prefix}-db-subnet-group"
  description = "Subnet group for ${var.project_name} PostgreSQL database"
  subnet_ids = [
    aws_subnet.database_subnet_1.id,
    aws_subnet.database_subnet_2.id,
    aws_subnet.database_subnet_3.id,
  ]

  tags = {
    Name        = "${local.name_prefix}-db-subnet-group"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "database-subnet-group"
  }
}

resource "aws_db_parameter_group" "postgres_params" {
  name   = "${local.name_prefix}-postgres-params"
  family = "postgres15"

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  parameter {
    name         = "log_statement"
    value        = local.environment == "prod" ? "ddl" : "none"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_min_duration_statement"
    value        = local.environment == "prod" ? "1000" : "-1"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_connections"
    value        = local.environment == "prod" ? "1" : "0"
    apply_method = "immediate"
  }

  parameter {
    name         = "log_disconnections"
    value        = local.environment == "prod" ? "1" : "0"
    apply_method = "immediate"
  }

  tags = {
    Name        = "${local.name_prefix}-postgres-params"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "postgres-parameter-group"
  }
}

resource "aws_db_instance" "postgres_db" {
  identifier     = local.name_prefix
  engine         = "postgres"
  engine_version = "15.13"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp3"
  storage_encrypted     = true

  db_name  = var.project_name
  username = var.user_database
  password = var.password_database

  db_subnet_group_name   = aws_db_subnet_group.subnet.name
  vpc_security_group_ids = [aws_security_group.database_security_group.id]
  parameter_group_name   = aws_db_parameter_group.postgres_params.name
  publicly_accessible    = false
  port                   = 5432

  backup_retention_period = local.environment == "prod" ? 7 : 0
  backup_window           = "03:00-04:00"
  copy_tags_to_snapshot   = true

  maintenance_window           = "Mon:00:00-Mon:01:00"
  auto_minor_version_upgrade   = true
  allow_major_version_upgrade  = false
  skip_final_snapshot          = true

  deletion_protection             = false
  monitoring_interval             = 0
  enabled_cloudwatch_logs_exports = []
  performance_insights_enabled    = false

  tags = {
    Name        = "${local.name_prefix}-postgres-db"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "application-database"
  }
}
