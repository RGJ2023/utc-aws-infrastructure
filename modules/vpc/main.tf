# ------------------------------------------------------------------------------
# VPC & Internet Gateway
# ------------------------------------------------------------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "${var.environment}-vpc" }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.environment}-igw" }
}

# ------------------------------------------------------------------------------
# Subnets (Public, Private App, Private DB)
# ------------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.environment}-public-subnet-${var.availability_zones[count.index]}" }
}

resource "aws_subnet" "private_app" {
  count             = length(var.private_app_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_app_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = { Name = "${var.environment}-private-app-subnet-${var.availability_zones[count.index]}" }
}

resource "aws_subnet" "private_db" {
  count             = length(var.private_db_cidrs)
  vpc_id            = aws_vpc.this.id
  cidr_block        = var.private_db_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = { Name = "${var.environment}-private-db-subnet-${var.availability_zones[count.index]}" }
}

# ------------------------------------------------------------------------------
# Single NAT Gateway (Cost-Optimized for Dev/Prod Baseline)
# ------------------------------------------------------------------------------
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = { Name = "${var.environment}-nat-eip" }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = { Name = "${var.environment}-nat-gw" }

  depends_on = [aws_internet_gateway.this]
}

# ------------------------------------------------------------------------------
# Route Tables
# ------------------------------------------------------------------------------
# Public Route Table (IGW)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = { Name = "${var.environment}-public-rt" }
}

# Private App Route Table (NAT Gateway)
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = { Name = "${var.environment}-private-app-rt" }
}

# Isolated Private DB Route Table (No Internet Outbound)
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.this.id

  tags = { Name = "${var.environment}-private-db-rt" }
}

# ------------------------------------------------------------------------------
# Route Table Associations
# ------------------------------------------------------------------------------
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private_app" {
  count          = length(aws_subnet.private_app)
  subnet_id      = aws_subnet.private_app[count.index].id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table_association" "private_db" {
  count          = length(aws_subnet.private_db)
  subnet_id      = aws_subnet.private_db[count.index].id
  route_table_id = aws_route_table.private_db.id
}