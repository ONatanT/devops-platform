#!/bin/bash

# Deploy infrastructure to specified environment
# Usage: ./scripts/deploy.sh <environment>
# Example: ./scripts/deploy.sh dev

set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
  echo "Error: Environment not specified"
  echo "Usage: ./deploy.sh <dev|staging|prod>"
  exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
  echo "Error: Invalid environment. Must be dev, staging, or prod"
  exit 1
fi

echo "========================================="
echo "Deploying to $ENVIRONMENT environment"
echo "========================================="

cd "infrastructure/environments/$ENVIRONMENT"

echo "Initializing Terraform..."
terraform init

echo "Planning changes..."
terraform plan -out=tfplan

echo ""
read -p "Apply these changes? (yes/no): " confirm

if [ "$confirm" == "yes" ]; then
  echo "Applying changes..."
  terraform apply tfplan
  rm tfplan
  
  echo ""
  echo "========================================="
  echo "Deployment complete!"
  echo "========================================="
  terraform output
else
  echo "Deployment cancelled"
  rm tfplan
fi
