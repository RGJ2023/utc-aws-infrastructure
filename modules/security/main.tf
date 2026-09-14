# ------------------------------------------------------------------------------
# 1. ALB Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "alb" {
  name        = "${var.environment}-alb-sg"
  description = "Allow HTTP/HTTPS from Internet"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.environment}-alb-sg"
    Environment = var.environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_egress" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ------------------------------------------------------------------------------
# 2. Bastion Host Security Group
# ------------------------------------------------------------------------------
# resource "aws_security_group" "bastion" {
#   name        = "${var.environment}-bastion-sg"
#   description = "Allow SSH from specific management IP"
#   vpc_id      = var.vpc_id

#   tags = {
#     Name        = "${var.environment}-bastion-sg"
#     Environment = var.environment
#   }
# }

# resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
#   security_group_id = aws_security_group.bastion.id
#   cidr_ipv4         = var.my_ip_cidr
#   from_port         = 22
#   to_port           = 22
#   ip_protocol       = "tcp"
# }

# resource "aws_vpc_security_group_egress_rule" "bastion_egress" {
#   security_group_id = aws_security_group.bastion.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1"
# }

# ------------------------------------------------------------------------------
# 3. Application Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "app" {
  name        = "${var.environment}-app-sg"
  description = "Allow HTTP from ALB and SSH from Bastion"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.environment}-app-sg"
    Environment = var.environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_http_from_alb" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

# resource "aws_vpc_security_group_ingress_rule" "app_ssh_from_bastion" {
#   security_group_id            = aws_security_group.app.id
#   referenced_security_group_id = aws_security_group.bastion.id
#   from_port                    = 22
#   to_port                      = 22
#   ip_protocol                  = "tcp"
# }

# Single full egress rule for app instances (pulling packages, updates, S3/CloudWatch traffic)
resource "aws_vpc_security_group_egress_rule" "app_egress" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ------------------------------------------------------------------------------
# 4. Database Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "db" {
  name        = "${var.environment}-db-sg"
  description = "Allow Database traffic from App Servers"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.environment}-db-sg"
    Environment = var.environment
  }
}

# Ingress: Supports MySQL (3306) or PostgreSQL (5432) via variable
resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "db_egress" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}