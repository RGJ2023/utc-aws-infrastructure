variable "environment" {
  type        = string
  description = "Target deployment environment (dev/prod)"
}

variable "vpc_id" {
  type        = string
  description = "ID of the target VPC"
}

variable "app_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs where EFS mount targets will be created"
}

variable "app_server_sg_id" {
  type        = string
  description = "ID of the Application Security Group allowed to mount EFS over NFS"
}