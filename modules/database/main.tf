resource "aws_db_subnet_group" "this" {
  name       = "utc-db-subnet-group"
  subnet_ids = var.db_subnet_ids

  tags = { Name = "utc-db-subnet-group" }
}

resource "aws_db_instance" "this" {
  identifier             = "utc-dev-database"
  allocated_storage      = 20
  max_allocated_storage  = 50
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "utcdb"
  username               = "admin"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_sg_id]
  multi_az               = false
  skip_final_snapshot    = true

  tags = { Name = "utc-dev-database" }
}