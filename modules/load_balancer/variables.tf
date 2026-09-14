variable "vpc_id" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "alb_sg_id" { type = string }
variable "domain_name" { type = string }
variable "subdomain" { type = string }
variable "environment" {
  type        = string
  description = "Deployment Environment"
}