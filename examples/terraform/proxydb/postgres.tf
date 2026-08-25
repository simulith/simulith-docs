resource "aws_security_group" "database_security_group" {
  name        = "${local.name_prefix}-database-sg"
  description = "Security group for PostgreSQL database"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "PostgreSQL access from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
  publicly_accessible    = false
  port                   = 5432

  skip_final_snapshot = true
}
