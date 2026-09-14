resource "aws_db_subnet_group" "this" {
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name        = "${var.environment}-db-subnet-group"
    Environment = var.environment
  }
}

resource "aws_db_instance" "this" {
  identifier = "${var.environment}-database"

  # Storage Sizing
  allocated_storage     = var.environment == "prod" ? 50 : 20
  max_allocated_storage = var.environment == "prod" ? 100 : 50

  # Engine Configuration
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.environment == "prod" ? "db.t3.small" : "db.t3.micro"

  db_name  = "utcdb"
  username = "admin"
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_sg_id]

  # Production Hardening & High Availability
  multi_az                  = var.environment == "prod" ? true : false
  storage_encrypted         = true
  deletion_protection       = var.environment == "prod" ? true : false
  skip_final_snapshot       = var.environment == "prod" ? false : true
  final_snapshot_identifier = var.environment == "prod" ? "${var.environment}-db-final-snapshot" : null

  tags = {
    Name        = "${var.environment}-database"
    Environment = var.environment
  }
}