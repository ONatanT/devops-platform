terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
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

locals {
  environment = "dev"
  aws_region  = "us-east-1"
}

# Networking
module "networking" {
  source = "../../modules/networking"

  environment        = local.environment
  vpc_cidr          = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b"]
  enable_nat_gateway = true
}

# ECR Repository
module "ecr" {
  source = "../../modules/ecr"

  environment = local.environment
  app_name    = "backend-api"
}

# Application Load Balancer
module "alb" {
  source = "../../modules/alb"

  environment        = local.environment
  vpc_id             = module.networking.vpc_id
  public_subnet_ids  = module.networking.public_subnet_ids
  container_port     = 3000
  enable_deletion_protection = false
}

# ECS Cluster and Service
module "ecs" {
  source = "../../modules/ecs"

  environment            = local.environment
  app_name              = "backend-api"
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  alb_security_group_ids = [module.alb.security_group_id]
  target_group_arn      = module.alb.target_group_arn
  alb_listener_arn      = module.alb.http_listener_arn
  ecr_repository_url    = module.ecr.repository_url
  image_tag             = "latest"
  aws_region            = local.aws_region
  db_secret_arn = module.rds.secret_arn

  # Dev-specific settings
  task_cpu       = "256"
  task_memory    = "512"
  desired_count  = 1
  min_capacity   = 1
  max_capacity   = 2
}

# RDS PostgreSQL Database
module "rds" {
  source = "../../modules/rds"

  environment            = local.environment
  vpc_id                 = module.networking.vpc_id
  private_subnet_ids     = module.networking.private_subnet_ids
  ecs_security_group_ids = []

  # Dev-specific settings
  db_instance_class          = "db.t3.micro"
  allocated_storage          = 20
  max_allocated_storage      = 50
  multi_az                   = false  # Single AZ for dev
  backup_retention_days      = 1      # Minimal backups
  skip_final_snapshot        = true   # Don't need final snapshot in dev
  deletion_protection        = false  # Allow easy deletion
  enable_performance_insights = false # Save costs in dev
}

# Security group rule to allow ECS to access RDS
# This breaks the circular dependency by creating the rule separately
resource "aws_security_group_rule" "ecs_to_rds" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.rds.security_group_id
  source_security_group_id = module.ecs.security_group_id
  description              = "Allow ECS tasks to access RDS"
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

output "alb_dns_name" {
  description = "Load Balancer DNS name - Use this to access your application"
  value       = module.alb.alb_dns_name
}

output "ecr_repository_url" {
  description = "ECR repository URL - Push Docker images here"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "application_url" {
  description = "Application URL"
  value       = "http://${module.alb.alb_dns_name}"
}

output "db_endpoint" {
  description = "Database endpoint"
  value       = module.rds.db_instance_endpoint
}

output "db_secret_name" {
  description = "Database credentials secret name"
  value       = module.rds.secret_name
}

output "db_secret_arn" {
  description = "Database credentials secret ARN"
  value       = module.rds.secret_arn
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.rds.security_group_id
}

output "ecs_security_group_id" {
  description = "ECS security group ID"
  value       = module.ecs.security_group_id
}