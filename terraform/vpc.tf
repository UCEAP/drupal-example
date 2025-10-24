# CIDR Locals for consistent, readable subnet allocation
locals {
  vpc_cidr  = "10.${var.app_number}.0.0/16"

  # Public subnets (ALB)
  public_cidr_az1    = "10.${var.app_number}.0.0/24"
  public_cidr_az2    = "10.${var.app_number}.1.0/24"

  # Private subnets (ECS Tasks)
  private_cidr_az1   = "10.${var.app_number}.10.0/24"
  private_cidr_az2   = "10.${var.app_number}.11.0/24"

  # Database subnets (RDS/Redis)
  database_cidr_az1  = "10.${var.app_number}.20.0/24"
  database_cidr_az2  = "10.${var.app_number}.21.0/24"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-igw"
  }
}

# Public Subnets (for ALB)
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = count.index == 0 ? local.public_cidr_az1 : local.public_cidr_az2
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.name_prefix}-public-${var.availability_zones[count.index]}"
    Type = "public"
  }
}

# Private Subnets (for ECS Tasks)
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = count.index == 0 ? local.private_cidr_az1 : local.private_cidr_az2
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name_prefix}-private-${var.availability_zones[count.index]}"
    Type = "private"
  }
}

# Database Subnets (for RDS and ElastiCache)
resource "aws_subnet" "database" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = count.index == 0 ? local.database_cidr_az1 : local.database_cidr_az2
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${var.name_prefix}-database-${var.availability_zones[count.index]}"
    Type = "database"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = {
    Name = "${var.name_prefix}-nat-eip-${var.availability_zones[count.index]}"
  }

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateway (in public subnets)
resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.name_prefix}-nat-${var.availability_zones[count.index]}"
  }

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.name_prefix}-public-rt"
  }
}

# Public Route Table Association
resource "aws_route_table_association" "public" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Tables (one per AZ for NAT Gateway)
resource "aws_route_table" "private" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = {
    Name = "${var.name_prefix}-private-rt-${var.availability_zones[count.index]}"
  }
}

# Private Route Table Association
resource "aws_route_table_association" "private" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Database Route Table (no internet access)
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.name_prefix}-database-rt"
  }
}

# Database Route Table Association
resource "aws_route_table_association" "database" {
  count          = length(var.availability_zones)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# DB Subnet Group for RDS
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "${var.name_prefix}-db-subnet-group"
  }
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.name_prefix}-redis-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "${var.name_prefix}-redis-subnet-group"
  }
}
