output "efs_id" {
  value       = aws_efs_file_system.this.id
  description = "ID of the EFS File System"
}

output "efs_dns_name" {
  value       = aws_efs_file_system.this.dns_name
  description = "DNS name of the EFS File System for mounting"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.logs.id
  description = "Name of the S3 logs and backups bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.logs.arn
  description = "ARN of the S3 logs and backups bucket"
}