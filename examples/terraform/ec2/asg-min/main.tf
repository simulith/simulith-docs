# Auto Scaling group + launch template green path.

locals {
  environment = var.environment
  name_prefix = "${var.project_name}-${local.environment}"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${local.name_prefix}-VPC"
    Environment = local.environment
  }
}

resource "aws_subnet" "app" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${local.name_prefix}-app-subnet"
  }
}

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-asg-sg"
  description = "Simulith ASG SSH ingress for sidecar"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-asg-sg"
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "${local.name_prefix}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.app.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.name_prefix}-asg-member"
    }
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${local.name_prefix}-asg"
  vpc_zone_identifier = [aws_subnet.app.id]
  desired_capacity    = 1
  max_size            = 2
  min_size            = 1

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-asg"
    propagate_at_launch = true
  }
}
