# ------------------------------------------------------------------------------
# 1. S3 Bucket for Logs & Backups
# ------------------------------------------------------------------------------
resource "aws_s3_bucket" "logs" {
  bucket_prefix = "${var.environment}-utc-logs-backup-"
  force_destroy = var.environment == "dev" ? true : false

  tags = {
    Name        = "${var.environment}-logs-backup"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
 

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
  
    }
  
  }
}

# Explicitly block public access to log & backup bucket
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# 2. Amazon EFS File System
# ------------------------------------------------------------------------------
resource "aws_efs_file_system" "this" {
  creation_token   = "${var.environment}-utc-shared-efs"
  performance_mode = "generalPurpose"
  encrypted        = true

  tags = {
    Name        = "${var.environment}-efs-shared"
    Environment = var.environment
  }
}

# ------------------------------------------------------------------------------
# 3. EFS Mount Target Security Group
# ------------------------------------------------------------------------------
resource "aws_security_group" "efs" {
  name        = "${var.environment}-efs-mount-sg"
  description = "Allow NFS traffic from App Servers"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.environment}-efs-mount-sg"
    Environment = var.environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_nfs" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = var.app_server_sg_id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "efs_egress" {
  security_group_id = aws_security_group.efs.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# ------------------------------------------------------------------------------
# 4. EFS Mount Targets
# ------------------------------------------------------------------------------
resource "aws_efs_mount_target" "this" {
  count           = length(var.app_subnet_ids)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.app_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}