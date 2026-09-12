variable "vpc_cidr" { type = string }
variable "public_subnet_cidrs" { type = list(string) }
variable "private_app_cidrs" { type = list(string) }
variable "private_db_cidrs" { type = list(string) }
variable "availability_zones" { type = list(string) }
variable "environment" {
  type        = string
  description = "Deployment Environment"
}