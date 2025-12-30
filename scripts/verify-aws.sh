#!/bin/bash

# Verify AWS resources across all environments
# Usage: ./scripts/verify-aws.sh

echo "========================================="
echo "AWS Resources Verification"
echo "========================================="

echo ""
echo "AWS Identity:"
aws sts get-caller-identity

echo ""
echo "All VPCs:"
aws ec2 describe-vpcs --region us-east-1 \
  --query 'Vpcs[*].{Name:Tags[?Key==`Name`]|[0].Value, VpcId:VpcId, CIDR:CidrBlock, Env:Tags[?Key==`Environment`]|[0].Value}' \
  --output table

echo ""
echo "Dev Environment Subnets:"
aws ec2 describe-subnets --region us-east-1 \
  --filters "Name=tag:Environment,Values=dev" \
  --query 'Subnets[*].{Name:Tags[?Key==`Name`]|[0].Value, SubnetId:SubnetId, CIDR:CidrBlock, AZ:AvailabilityZone, Tier:Tags[?Key==`Tier`]|[0].Value}' \
  --output table

echo ""
echo "NAT Gateways:"
aws ec2 describe-nat-gateways --region us-east-1 \
  --query 'NatGateways[*].{Name:Tags[?Key==`Name`]|[0].Value, NatGatewayId:NatGatewayId, State:State, Env:Tags[?Key==`Environment`]|[0].Value}' \
  --output table
