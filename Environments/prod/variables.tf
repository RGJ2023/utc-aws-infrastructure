variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS Deployment Region"
}

variable "environment" {
  type        = string
  description = "Deployment Environment"
}

variable "domain_name" {
  type        = string
  description = "Domain name associated with existing Route 53 hosted zone (e.g., example.com)"
}

variable "subdomain" {
  type        = string
  default     = "app"
  description = "Subdomain prefix for the application (e.g., app.example.com)"
}

variable "my_ip_cidr" {
  type        = string
  description = "Your local workstation IP in CIDR notation for Bastion SSH (e.g., 203.0.113.25/32)"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for EC2 instances (App and Bastion)"
}


variable "notification_email" {
  type        = string
  description = "Email address to receive Auto Scaling alarms"
}

variable "vpc_cidr" {
  type        = string
  description = "The IPv4 CIDR block for the VPC"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}

variable "private_app_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private application subnets"
}

variable "private_db_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private database subnets"
}
