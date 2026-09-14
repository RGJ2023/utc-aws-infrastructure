terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.61.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      Project     = "prod-utc-application"
      ManagedBy   = "Terraform"
    }
  }
}
terraform {
  backend "s3" {
    bucket = "terraform-ra-2026"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
    use_lockfile = true
    encrypt = true
  }
}