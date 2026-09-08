output "s3_bucket_name" { value = aws_s3_bucket.logs.id }
output "efs_id" { value = aws_efs_file_system.this.id }