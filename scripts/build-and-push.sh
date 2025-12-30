#!/bin/bash

# Build and push Docker image to ECR with correct platform
# Usage: ./scripts/build-and-push.sh <environment> [tag]
# Example: ./scripts/build-and-push.sh dev v1.0.0

set -e

ENVIRONMENT=$1
TAG=${2:-latest}

if [ -z "$ENVIRONMENT" ]; then
  echo "Error: Environment not specified"
  echo "Usage: ./build-and-push.sh <dev|staging|prod> [tag]"
  exit 1
fi

echo "========================================="
echo "Building and Pushing Docker Image"
echo "Environment: $ENVIRONMENT"
echo "Tag: $TAG"
echo "Platform: linux/amd64 (AWS Fargate compatible)"
echo "========================================="

# Get ECR repository URL
cd "infrastructure/environments/$ENVIRONMENT"
ECR_URL=$(terraform output -raw ecr_repository_url)
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "ECR Repository: $ECR_URL"

# Login to ECR
echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build image with correct platform
echo "Building Docker image for linux/amd64..."
cd ../../../application/backend
docker build --platform linux/amd64 -t backend-api:$TAG .

# Tag for ECR
echo "Tagging image..."
docker tag backend-api:$TAG "$ECR_URL:$TAG"
docker tag backend-api:$TAG "$ECR_URL:latest"

# Push to ECR
echo "Pushing to ECR..."
docker push "$ECR_URL:$TAG"
docker push "$ECR_URL:latest"

echo ""
echo "========================================="
echo "✅ Image pushed successfully!"
echo "Repository: $ECR_URL"
echo "Tags: $TAG, latest"
echo "Platform: linux/amd64"
echo "========================================="
echo ""
echo "To deploy the new image, run:"
echo "  ./scripts/deploy-app.sh $ENVIRONMENT"
