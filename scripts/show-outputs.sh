#!/bin/bash

# Show outputs for all environments
# Usage: ./scripts/show-outputs.sh

echo "========================================="
echo "Infrastructure Outputs"
echo "========================================="

for env in dev staging prod; do
  if [ -d "infrastructure/environments/$env" ]; then
    echo ""
    echo "--- $env Environment ---"
    cd "infrastructure/environments/$env"
    
    if [ -f "terraform.tfstate" ]; then
      terraform output
    else
      echo "Not deployed yet"
    fi
    
    cd - > /dev/null
  fi
done
