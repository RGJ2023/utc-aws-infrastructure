variable "vpc_id" { type = string }
variable "public_subnet_1a_id" { type = string }
variable "private_app_subnets" { type = list(string) }
variable "bastion_sg_id" { type = string }
variable "app_sg_id" { type = string }
variable "target_group_arn" { type = string }
variable "ami_id" { type = string }
variable "efs_id" { type = string }