#!/bin/bash

# Destroy infrastructure in specified environment
# Usage: ./scripts/destroy.sh <environment>
# Example: ./scripts/destroy.sh dev

set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
  echo "Error: Environment not specified"
  echo "Usage: ./destroy.sh <dev|staging|prod>"
  exit 1
fi

echo "========================================="
echo "⚠️  WARNING: DESTROYING $ENVIRONMENT"
echo "========================================="
echo "This will permanently delete:"
echo "  - VPC and all subnets"
echo "  - NAT Gateways and Elastic IPs"
echo "  - All associated resources"
echo ""

read -p "Type '$ENVIRONMENT' to confirm destruction: " confirm

if [ "$confirm" == "$ENVIRONMENT" ]; then
  cd "infrastructure/environments/$ENVIRONMENT"
  
  echo "Destroying infrastructure..."
  terraform destroy
  
  echo "Destruction complete"
else
  echo "Destruction cancelled"
fi
