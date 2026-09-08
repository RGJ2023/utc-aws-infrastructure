# S3 Bucket for Logs & Backups
resource "aws_s3_bucket" "logs" {
  bucket_prefix = "utc-logs-backup-"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# EFS File System
resource "aws_efs_file_system" "this" {
  creation_token   = "utc-shared-efs"
  performance_mode = "generalPurpose"
  encrypted        = true

  tags = { Name = "Amazon EFS Shared File System" }
}

# EFS Mount Targets Security Group
resource "aws_security_group" "efs" {
  name        = "EFS-Mount-SG"
  description = "Allow NFS traffic from App Servers"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "efs_nfs" {
  security_group_id            = aws_security_group.efs.id
  referenced_security_group_id = var.app_server_sg_id
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
}

resource "aws_efs_mount_target" "this" {
  count           = length(var.app_subnet_ids)
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = var.app_subnet_ids[count.index]
  security_groups = [aws_security_group.efs.id]
}