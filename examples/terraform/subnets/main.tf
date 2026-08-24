# Production subnets/ root pattern — 6 database subnets + route table associations (generic demoapp).

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
    Type        = "public"
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
    Type        = "public"
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
    Type        = "public"
  }
}

resource "aws_subnet" "database_subnet_4" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.name_prefix}-database-subnet-4"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "rds-proxy-private"
    Type        = "private"
  }
}

resource "aws_subnet" "database_subnet_5" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.name_prefix}-database-subnet-5"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "rds-proxy-private"
    Type        = "private"
  }
}

resource "aws_subnet" "database_subnet_6" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.6.0/24"
  availability_zone       = "${var.aws_region}c"
  map_public_ip_on_launch = false

  tags = {
    Name        = "${local.name_prefix}-database-subnet-6"
    Environment = local.environment
    ManagedBy   = "terraform"
    Purpose     = "rds-proxy-private"
    Type        = "private"
  }
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.database_subnet_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.database_subnet_2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_3" {
  subnet_id      = aws_subnet.database_subnet_3.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.database_subnet_4.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.database_subnet_5.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_3" {
  subnet_id      = aws_subnet.database_subnet_6.id
  route_table_id = aws_route_table.private.id
}
