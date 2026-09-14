variable "environment" {
  type        = string
  description = "Target environment (dev/prod)"
}

variable "vpc_cidr" {
  type        = string
  description = "Base CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}

variable "private_app_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private app subnets"
}

variable "private_db_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private db subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of Availability Zones to deploy subnets into"
}