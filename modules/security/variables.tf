variable "environment" {
  type        = string
  description = "Target deployment environment (dev/prod)"
}

variable "vpc_id" {
  type        = string
  description = "ID of the target VPC"
}

variable "my_ip_cidr" {
  type        = string
  description = "Management IP CIDR block for SSH access to Bastion (e.g. 203.0.113.5/32)"
}

variable "db_port" {
  type        = number
  description = "Database port (e.g. 3306 for MySQL, 5432 for PostgreSQL)"
  default     = 3306
}