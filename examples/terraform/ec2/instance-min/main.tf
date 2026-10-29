# Minimum EC2 instance on Simulith.
# VPC + subnet + security group + aws_instance apply/destroy green path.

locals {
  environment = var.environment
  name_prefix = "${var.project_name}-${local.environment}"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${local.name_prefix}-VPC"
    Environment = local.environment
  }
}

resource "aws_subnet" "app" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${local.name_prefix}-app-subnet"
  }
}

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Simulith EC2 instance-min security group"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-app-sg"
  }
}

resource "aws_instance" "app" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.app.id
  vpc_security_group_ids = [aws_security_group.app.id]

  tags = {
    Name        = "${local.name_prefix}-app"
    Environment = local.environment
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = aws_subnet.app.availability_zone
  size              = 8
  type              = "gp3"

  tags = {
    Name = "${local.name_prefix}-data"
  }
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.app.id
}
