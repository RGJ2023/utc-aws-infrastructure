
module "vpc" {
  source = "../../modules/vpc"
  environment = var.environment

  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  private_app_cidrs   = var.private_app_cidrs
  private_db_cidrs    = var.private_db_cidrs
  availability_zones  = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
}

module "security" {
  source = "../../modules/security"

  vpc_id     = module.vpc.vpc_id
  my_ip_cidr = var.my_ip_cidr
}
module "storage" {
  source = "../../modules/storage" # Updated relative path

  vpc_id           = module.vpc.vpc_id
  app_subnet_ids   = module.vpc.private_app_subnet_ids
  app_server_sg_id = module.security.app_sg_id
}



module "load_balancer" {
  source = "../../modules/load_balancer" # Updated relative path

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  domain_name       = var.domain_name
  subdomain         = var.subdomain
}

module "compute" {
  source = "../../modules/compute" # Updated relative path

  vpc_id              = module.vpc.vpc_id
  public_subnet_1a_id = module.vpc.public_subnet_ids[0]
  private_app_subnets = module.vpc.private_app_subnet_ids
  bastion_sg_id       = module.security.bastion_sg_id
  app_sg_id           = module.security.app_sg_id
  target_group_arn    = module.load_balancer.target_group_arn
  ami_id              = var.ami_id
  efs_id              = module.storage.efs_id
}

module "monitoring" {
  source = "../../modules/monitoring"

  asg_name           = module.compute.asg_name
  scale_out_policy   = module.compute.scale_out_policy_arn
  notification_email = var.notification_email
}

# 1. Generate a random password automatically
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 2. Store that generated password inside AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.environment}/database/master_password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# 3. Pass the generated password into the single database module
module "database" {
  source = "../../modules/database"

  db_subnet_ids = module.vpc.private_db_subnet_ids
  db_sg_id      = module.security.db_sg_id
  db_password   = random_password.db_password.result
}