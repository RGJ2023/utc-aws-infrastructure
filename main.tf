module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = "10.10.0.0/16"
  public_subnet_cidrs  = ["10.10.0.0/20", "10.10.16.0/20", "10.10.32.0/20"]
  private_app_cidrs    = ["10.10.64.0/20", "10.10.80.0/20", "10.10.96.0/20"]
  private_db_cidrs     = ["10.10.112.0/20", "10.10.128.0/20", "10.10.144.0/20"]
  availability_zones   = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
}

module "security" {
  source = "./modules/security"

  vpc_id     = module.vpc.vpc_id
  my_ip_cidr = var.my_ip_cidr
}

module "storage" {
  source = "./modules/storage"

  vpc_id             = module.vpc.vpc_id
  app_subnet_ids     = module.vpc.private_app_subnet_ids
  app_server_sg_id   = module.security.app_sg_id
}

module "database" {
  source = "./modules/database"

  db_subnet_ids = module.vpc.private_db_subnet_ids
  db_sg_id      = module.security.db_sg_id
  db_password   = var.db_password
}

module "load_balancer" {
  source = "./modules/load_balancer"

  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security.alb_sg_id
  domain_name       = var.domain_name
  subdomain         = var.subdomain
}

module "compute" {
  source = "./modules/compute"

  vpc_id               = module.vpc.vpc_id
  public_subnet_1a_id  = module.vpc.public_subnet_ids[0]
  private_app_subnets  = module.vpc.private_app_subnet_ids
  bastion_sg_id        = module.security.bastion_sg_id
  app_sg_id            = module.security.app_sg_id
  target_group_arn     = module.load_balancer.target_group_arn
  ami_id               = var.ami_id
  efs_id               = module.storage.efs_id
}

module "monitoring" {
  source = "./modules/monitoring"

  asg_name           = module.compute.asg_name
  scale_out_policy   = module.compute.scale_out_policy_arn
  notification_email = var.notification_email
}
