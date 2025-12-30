#!/bin/bash

# Monitor ECS service in real-time
# Usage: ./scripts/monitor-ecs.sh [environment]
# Example: ./scripts/monitor-ecs.sh dev

ENVIRONMENT=${1:-dev}
CLUSTER="${ENVIRONMENT}-cluster"
SERVICE="${ENVIRONMENT}-backend-api-service"
REGION="us-east-1"

echo "Monitoring ECS Service: $SERVICE"
echo "Press Ctrl+C to stop"
echo ""

while true; do
  clear
  echo "╔════════════════════════════════════════════════════════════╗"
  echo "║  ECS Service Monitor - $(date +'%Y-%m-%d %H:%M:%S')          ║"
  echo "╚════════════════════════════════════════════════════════════╝"
  echo ""
  
  # Service status
  aws ecs describe-services \
    --cluster $CLUSTER \
    --services $SERVICE \
    --region $REGION \
    --query "services[0].{Status:status,Running:runningCount,Desired:desiredCount,Pending:pendingCount}" \
    --output table
  
  echo ""
  echo "Recent Events:"
  aws ecs describe-services \
    --cluster $CLUSTER \
    --services $SERVICE \
    --region $REGION \
    --query "services[0].events[:3].{Time:createdAt,Message:message}" \
    --output table
  
  echo ""
  echo "Press Ctrl+C to stop monitoring..."
  sleep 5
done
