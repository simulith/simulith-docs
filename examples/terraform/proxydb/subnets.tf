resource "aws_subnet" "database_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${local.name_prefix}-database-subnet-1"
  }
}

resource "aws_subnet" "database_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "${local.name_prefix}-database-subnet-2"
  }
}

resource "aws_subnet" "database_subnet_3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${local.name_prefix}-database-subnet-3"
  }
}

resource "aws_subnet" "database_subnet_4" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "${local.name_prefix}-database-subnet-4"
  }
}

resource "aws_subnet" "database_subnet_5" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "${var.aws_region}b"

  tags = {
    Name = "${local.name_prefix}-database-subnet-5"
  }
}

resource "aws_subnet" "database_subnet_6" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "${var.aws_region}c"

  tags = {
    Name = "${local.name_prefix}-database-subnet-6"
  }
}
