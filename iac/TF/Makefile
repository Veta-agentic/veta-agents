# Makefile for Terraform operations

.PHONY: help init validate fmt plan apply destroy clean

# Default target
help:
@echo "Terraform Makefile for Veta Agents Infrastructure"
@echo ""
@echo "Available targets:"
@echo "  init      - Initialize Terraform working directory"
@echo "  validate  - Validate Terraform configuration"
@echo "  fmt       - Format Terraform files"
@echo "  plan      - Generate and show execution plan"
@echo "  apply     - Build or change infrastructure"
@echo "  destroy   - Destroy Terraform-managed infrastructure"
@echo "  clean     - Remove Terraform cache and state files (local only)"
@echo "  output    - Show output values"

# Initialize Terraform
init:
@echo "Initializing Terraform..."
cd iac/TF && terraform init

# Validate configuration
validate:
@echo "Validating Terraform configuration..."
cd iac/TF && terraform validate

# Format Terraform files
fmt:
@echo "Formatting Terraform files..."
cd iac/TF && terraform fmt -recursive

# Generate execution plan
plan:
@echo "Generating execution plan..."
cd iac/TF && terraform plan -out=tfplan

# Apply changes
apply:
@echo "Applying Terraform changes..."
cd iac/TF && terraform apply tfplan

# Apply without plan file (with auto-approve)
apply-auto:
@echo "Applying Terraform changes (auto-approve)..."
cd iac/TF && terraform apply -auto-approve

# Destroy infrastructure
destroy:
@echo "Destroying infrastructure..."
cd iac/TF && terraform destroy

# Show outputs
output:
@echo "Showing Terraform outputs..."
cd iac/TF && terraform output

# Clean local files
clean:
@echo "Cleaning Terraform cache and local state..."
cd iac/TF && rm -rf .terraform terraform.tfstate* tfplan

# Pre-commit checks
pre-commit: fmt validate
@echo "Pre-commit checks passed!"
