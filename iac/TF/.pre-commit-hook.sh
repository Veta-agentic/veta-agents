#!/bin/sh
# Pre-commit hook for Terraform validation

echo "Running Terraform pre-commit checks..."

# Change to Terraform directory
cd iac/TF || exit 1

# Format check
echo "1. Checking Terraform formatting..."
if ! terraform fmt -check -recursive; then
    echo "ERROR: Terraform files are not formatted correctly."
    echo "Run 'terraform fmt -recursive' to fix formatting."
    exit 1
fi

# Validation check
echo "2. Validating Terraform configuration..."
if ! terraform validate; then
    echo "ERROR: Terraform configuration is invalid."
    exit 1
fi

echo "✓ All pre-commit checks passed!"
exit 0
