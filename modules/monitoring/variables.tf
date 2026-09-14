variable "environment" {
  type        = string
  description = "Target deployment environment (dev/prod)"
}

variable "notification_email" {
  type        = string
  description = "Email address for SNS alert notifications"
}

variable "asg_name" {
  type        = string
  description = "Name of the target Auto Scaling Group"
}

variable "scale_out_policy" {
  type        = string
  description = "ARN of the Auto Scaling Group scale-out policy"
}

variable "scale_in_policy" {
  type        = string
  description = "ARN of the Auto Scaling Group scale-in policy"
}