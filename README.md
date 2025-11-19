# Elekta DevOps Assessment - Infrastructure Deployment Pipeline

## Overview
This project demonstrates Infrastructure as Code (IaC) using Terraform to provision Azure infrastructure, with automated CI/CD using GitHub Actions.

## Architecture
- **2x Windows Server 2022 VMs** (vm-test-1, vm-test-2)
- **Virtual Network** with subnet and Network Security Group
- **Security**: RDP access enabled with NSG rules
- **State Management**: Azure Storage Account with Terraform state

## Prerequisites
- Azure Subscription
- GitHub Account
- Terraform installed locally (v1.5+)
- Azure CLI installed

## Project Structure
```
terraform/
├── main.tf              # Core infrastructure resources
├── variables.tf         # Variable definitions
├── outputs.tf           # Output values
├── provider.tf          # Azure provider and backend config
├── terraform.tfvars     # Environment-specific values (DO NOT COMMIT)
└── backend-config.hcl   # Backend configuration (DO NOT COMMIT)

.github/workflows/
└── terraform-deploy.yml # GitHub Actions CI/CD pipeline
```

## Setup Instructions

### 1. Local Development Setup
```bash
# Clone repository
git clone https://github.com/Ndekevin/elekta-devops-assessment.git
cd elekta-devops-assessment

# Authenticate with Azure
az login

# Create terraform.tfvars (update values)
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars with your subscription ID and values

# Initialize Terraform
cd terraform
terraform init
```

### 2. Create Azure Resources for State Management
```bash
# Create resource group and storage account (one-time setup)
az group create --name rg-terraform-state --location eastus

az storage account create \
  --name tfstatestg<yourname> \
  --resource-group rg-terraform-state \
  --location eastus \
  --sku Standard_LRS

az storage container create \
  --name tfstate \
  --account-name tfstatestg<yourname>
```

### 3. Create Azure Service Principal for GitHub
```bash
az ad sp create-for-rbac \
  --name "github-devops-sp" \
  --role Contributor \
  --scopes /subscriptions/<YOUR_SUBSCRIPTION_ID>
```

### 4. Add GitHub Secrets
- Go to GitHub Repository → Settings → Secrets and variables → Actions
- Add the following secrets:
  - `AZURE_CLIENT_ID`
  - `AZURE_CLIENT_SECRET`
  - `AZURE_SUBSCRIPTION_ID`
  - `AZURE_TENANT_ID`
  - `ADMIN_PASSWORD`

### 5. Validate and Deploy Locally
```bash
cd terraform

# Validate syntax
terraform validate

# Plan infrastructure
terraform plan -out=tfplan

# Apply (creates resources)
terraform apply tfplan
```

## Deployment via GitHub Actions

Once the repository is pushed to GitHub:

1. **Pull Requests**: Triggers `terraform plan` and comments results on PR
2. **Merge to main**: Triggers full `terraform apply` automatically

Monitor pipeline at: **GitHub Repository → Actions tab**

## Outputs
After successful deployment, retrieve outputs:
```bash
terraform output
```

Outputs include:
- Virtual Machine names
- Public IP addresses
- Private IP addresses
- Resource Group name
- Virtual Network and Subnet IDs

## Security Considerations
- ✅ Credentials stored in GitHub Secrets (not in code)
- ✅ Terraform state encrypted in Azure Storage
- ✅ NSG restricts RDP access (currently open; restrict to specific IPs in production)
- ✅ Admin password stored securely as GitHub Secret
- ⚠️ In production: Restrict RDP source IP ranges

## Accessing VMs via RDP
```
Host: <public_ip_address>
Username: Elekta
Password: ElektaDevopsTest123!
```

From VM1 to VM2 (internal):
```
Host: <private_ip_vm2>
Username: Elekta
Password: ElektaDevopsTest123!
```

## Cost Management
- Standard_B2s VMs: ~$60-80/month each
- Storage Account: ~$1-2/month
- Public IPs: ~$3-5/month each
- Consider deleting resources when not needed

## Troubleshooting

### Terraform Init Fails
```bash
# Check Azure authentication
az account show

# Reinitialize with explicit backend config
terraform init -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=tfstatestg<yourname>" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=prod.terraform.tfstate"
```

### GitHub Actions Pipeline Fails
- Check GitHub Secrets are correctly set
- Verify Azure Service Principal has Contributor role
- Check logs in GitHub Actions tab for error details

### State Lock Issues
```bash
# If state is locked (from failed apply)
terraform force-unlock <LOCK_ID>
```

## Design Decisions
1. **Static Public IPs**: Used `Standard` allocation for consistent access
2. **Premium Storage**: Used Premium_LRS for OS disk for better performance
3. **Subnet CIDR**: Used 10.0.1.0/24 to allow future expansion
4. **NSG Rules**: Simplified for lab purposes; production requires stricter rules
5. **GitHub Actions**: Chosen for simplicity and native GitHub integration

## Cleanup
To destroy all resources:
```bash
cd terraform
terraform destroy
```

## References
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Terraform](https://github.com/hashicorp/setup-terraform)
- [Azure Terraform Backend](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)

---
