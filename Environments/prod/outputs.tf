output "alb_dns_name" {
  value       = module.load_balancer.alb_dns_name
  description = "DNS name of the Application Load Balancer"
}

output "application_url" {
  value       = module.load_balancer.application_url
  description = "Full URL for the deployed application"
}

# output "bastion_public_ip" {
#   value       = module.compute.bastion_public_ip
#   description = "Public IP address of the Bastion Host"
# }

output "database_endpoint" {
  value       = module.database.db_endpoint
  description = "Endpoint of the RDS MySQL Database"
}