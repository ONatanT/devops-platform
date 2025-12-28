terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # We'll add remote backend later
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "devops-platform"
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

# Local variables
locals {
  environment = "dev"
  aws_region  = "us-east-1"
}

# Deploy networking module
module "networking" {
  source = "../../modules/networking"

  environment        = local.environment
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  enable_nat_gateway = false  # Save money in dev - no NAT needed
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Outputs
output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnets" {
  value = module.networking.public_subnet_ids
}

output "private_subnets" {
  value = module.networking.private_subnet_ids
}