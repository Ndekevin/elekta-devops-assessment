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
2. **Merge to main**: Triggers `terraform apply` (may require manual approval in GitHub Environments if configured)

**Pipeline Stages:**
- **Validate**: Checks Terraform syntax and formatting
- **Plan**: Generates execution plan and uploads as artifact
- **Apply**: Deploys infrastructure changes (manual approval recommended for production)

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
```# Installing Terraform from HashiCorp Repository - Complete Guide

## Purpose & Overview

This document explains how to install and keep Terraform updated on your Linux (Ubuntu/Debian) system by adding HashiCorp's official repository. This is the **recommended way** to install Terraform because it:

- ✅ Installs the latest official version
- ✅ Makes updates simple (`apt-get upgrade`)
- ✅ Uses GPG verification for security
- ✅ Works across multiple machines using the same commands
- ✅ Eliminates manual downloads and extractions

---

## Prerequisites

Before starting, ensure you have:

- Ubuntu or Debian-based Linux system
- `sudo` (administrative) access
- Internet connection
- Approximately 100MB free disk space
- Basic command-line familiarity

Check your system:
```bash
# Check Ubuntu version
lsb_release -a

# Check if you have sudo access
sudo whoami  # Should output: root
```

---

## Installation Steps

### Step 1: Download and Install HashiCorp's GPG Key

**What this does**: Downloads HashiCorp's public GPG key (used to verify Terraform packages are authentic)

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

**Breaking it down**:
- `wget -O-` = Download file and output to stdout
- `https://apt.releases.hashicorp.com/gpg` = HashiCorp's GPG key URL
- `|` = Pipe (send output to next command)
- `sudo gpg --dearmor` = Convert key to binary format (requires sudo for system access)
- `-o /usr/share/keyrings/hashicorp-archive-keyring.gpg` = Save to system keyring directory

**Verification**:
```bash
# Verify the key was installed
ls -la /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Should show output like:
# -rw-r--r-- 1 root root 3522 Nov 15 10:30 /usr/share/keyrings/hashicorp-archive-keyring.gpg
```

---

### Step 2: Add HashiCorp's Repository to Your System

**What this does**: Adds HashiCorp's package repository to your system's list of software sources

```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```

**What each part does**:

| Part | Purpose | Example Output |
|------|---------|-----------------|
| `dpkg --print-architecture` | Detects your CPU architecture | `amd64` or `arm64` |
| `grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release` | Detects Ubuntu version | `jammy`, `focal`, `bionic` |
| `lsb_release -cs` | Fallback if grep fails | `jammy` (Ubuntu 22.04) |
| `https://apt.releases.hashicorp.com` | HashiCorp's repository URL | Repository server location |
| `/etc/apt/sources.list.d/hashicorp.list` | Repository config file location | System-wide repository list |

**What gets written to the file**:

After running the command, your system creates `/etc/apt/sources.list.d/hashicorp.list` containing:

```
deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com jammy main
```

(Example for Ubuntu 22.04 with amd64 architecture)

**Verification**:
```bash
# Check the file was created
cat /etc/apt/sources.list.d/hashicorp.list

# Should output the repository line above
```

---

### Step 3: Update Your Package Manager's Cache

**What this does**: Tells `apt` to download the latest package list from all repositories (including HashiCorp's new one)

```bash
sudo apt-get update
```

**Why it's needed**: Your system needs to know what packages are available in the new repository

**What happens**:
```
Hit:1 http://archive.ubuntu.com/ubuntu jammy InRelease
Get:2 https://apt.releases.hashicorp.com jammy InRelease
Hit:3 http://security.ubuntu.com/ubuntu jammy-security InRelease
Reading package lists... Done
```

---

### Step 4: Install Terraform

**What this does**: Downloads and installs Terraform from HashiCorp's repository

```bash
sudo apt-get install terraform
```

**What happens**:
```
Reading package lists... Done
Building dependency tree... Done
The following NEW packages will be installed:
  terraform
0 upgraded, 1 newly installed, 0 to remove
Need to get 26.5 MB of archives.
...
Setting up terraform (1.5.7+1) ...
```

---

### Step 5: Verify Terraform Installation

**What this does**: Confirms Terraform is installed and working correctly

```bash
terraform version
```

**Expected output**:
```
Terraform v1.5.7
on linux_amd64

Your version of Terraform is out of date! The latest version
is 1.6.0. You can update by downloading from https://www.terraform.io/downloads.html
```

✅ **Success indicator**: You see a version number

---

## Quick Reference Commands

```bash
# Check installed version
terraform version

# List terraform in available packages
apt-cache policy terraform

# Search for other HashiCorp tools
apt-cache search hashicorp

# Upgrade terraform to latest version
sudo apt-get upgrade terraform

# Remove terraform
sudo apt-get remove terraform
```

---

## Elekta DevOps Assessment - Infrastructure Deployment Pipeline

### Overview

This project demonstrates Infrastructure as Code (IaC) using Terraform to provision Azure infrastructure, with an automated four-stage CI/CD pipeline using GitHub Actions.

**Architecture**:
- 2x Windows Server 2022 VMs (vm-test-1, vm-test-2)
- Virtual Network with subnet and Network Security Group
- Security: RDP access enabled with NSG rules for inter-VM communication
- State Management: Remote state in Azure Storage with DynamoDB-style locking

---

## Project Structure

```
elekta-devops-assessment/
├── terraform/
│   ├── main.tf              # Core infrastructure resources
│   ├── variables.tf         # Variable definitions
│   ├── outputs.tf           # Output values
│   ├── provider.tf          # Azure provider and backend config
│   ├── terraform.tfvars     # Environment-specific values (DO NOT COMMIT)
│   └── terraform.tfvars.example  # Template for terraform.tfvars
├── .github/
│   └── workflows/
│       └── terraform-deploy.yml   # GitHub Actions CI/CD pipeline (4 stages)
├── docs/
│   ├── screenshots/         # Azure Portal verification screenshots
│   └── architecture.md      # Architecture documentation
├── README.md                # This file
└── .gitignore              # Git ignore configuration
```

---

## Prerequisites

- Azure Subscription
- GitHub Account
- Terraform installed locally (v1.5+)
- Azure CLI installed
- `sudo` access on local machine

---

## Setup Instructions

### 1. Local Development Setup

```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/elekta-devops-assessment.git
cd elekta-devops-assessment

# Authenticate with Azure
az login

# Create terraform.tfvars from template
cp terraform/terraform.tfvars.example terraform/terraform.tfvars

# Edit terraform.tfvars with your subscription ID and values
nano terraform/terraform.tfvars

# Initialize Terraform
cd terraform
terraform init
```

---

### 2. Create Azure Resources for State Management (One-Time Setup)

```bash
# Create resource group for state storage
az group create --name rg-terraform-state --location eastus

# Create storage account (MUST BE lowercase)
az storage account create \
  --name tfstatestgelekta \
  --resource-group rg-terraform-state \
  --location eastus \
  --sku Standard_LRS

# Create blob container for state
az storage container create \
  --name tfstate \
  --account-name tfstatestgelekta

# Verify the container was created
az storage container list --account-name tfstatestgelekta --output table
```

**Important**: Storage account names must be **all lowercase** (Azure requirement)

---

### 3. Create Azure Service Principal for GitHub

```bash
# Create service principal with Contributor role
az ad sp create-for-rbac \
  --name "github-devops-sp" \
  --role Contributor \
  --scopes /subscriptions/YOUR_SUBSCRIPTION_ID

# Save the output - you'll need these values for GitHub Secrets
```

**Output includes**:
- `appId` → `AZURE_CLIENT_ID`
- `password` → `AZURE_CLIENT_SECRET`
- `tenant` → `AZURE_TENANT_ID`

---

### 4. Add GitHub Secrets

Go to **GitHub Repository Settings → Secrets and variables → Actions** and add:

| Secret Name | Value |
|---|---|
| `AZURE_CLIENT_ID` | Service Principal appId |
| `AZURE_CLIENT_SECRET` | Service Principal password |
| `AZURE_SUBSCRIPTION_ID` | Your Azure subscription ID |
| `AZURE_TENANT_ID` | Service Principal tenant |
| `ADMIN_PASSWORD` | `ElektaDevopsTest123!` |

**Important**: Never commit these values to GitHub

---

### 5. Create GitHub Environment (Optional but Recommended)

For production-grade approval workflows:

1. Go to **Settings → Environments → New environment**
2. Name it: `production`
3. Under "Required reviewers", add yourself or team members
4. Save

This adds a manual approval step before infrastructure is deployed.

---

### 6. Validate and Deploy Locally (Optional)

```bash
cd terraform

# Validate syntax
terraform validate

# Plan infrastructure (dry-run)
terraform plan -out=tfplan

# Apply (creates actual resources)
terraform apply tfplan

# Show outputs
terraform output
```

---

## CI/CD Pipeline Documentation

### Pipeline Overview

The GitHub Actions pipeline (`terraform-deploy.yml`) automates infrastructure deployment with four distinct stages and a manual approval gate before production deployment.

**Trigger Events**:
- **Push to main**: Triggers full pipeline (validate → plan → deploy with approval)
- **Pull Request**: Triggers validate and plan only (no deployment)
- **Manual trigger** (`workflow_dispatch`): Run pipeline manually from Actions tab

---

### Stage 1: Validation

**Runs**: On every push and PR
**Purpose**: Catch configuration errors and security issues early

**Steps**:

#### Format Check
```yaml
- name: 'Terraform Format Check'
```
- Validates code follows Terraform style standards
- Ensures consistent indentation and spacing
- **Impact**: Non-blocking (continues even if fails)

#### Backend Initialization
```yaml
- name: 'Terraform Init'
```
- Initializes Terraform working directory
- Downloads Azure provider plugin
- Connects to Azure Storage backend
- **Impact**: Critical - fails pipeline if it fails

#### Syntax Validation
```yaml
- name: 'Terraform Validate'
```
- Checks Terraform configuration syntax
- Verifies Azure provider compatibility
- Catches configuration errors early
- **Impact**: Critical

#### Security Scan (tfsec)
```yaml
- name: 'Terraform Security Scan (tfsec)'
```
- Detects infrastructure misconfigurations
- Checks for:
  - Overly permissive security groups
  - Encryption disabled
  - Weak authentication
  - Default passwords
- **Impact**: Non-blocking (shows issues but allows continuation)

#### Compliance Check (Checkov)
```yaml
- name: 'Policy Compliance Check (Checkov)'
```
- Validates compliance with infrastructure standards
- Checks for:
  - Missing resource tags
  - Encryption requirements
  - Logging configuration
  - RBAC policies
- **Impact**: Non-blocking (advisory only)

**Output**: GitHub step summary showing all validation results

---

### Stage 2: Terraform Plan

**Runs**: After validation succeeds
**Purpose**: Show what changes will be made before applying

**Steps**:

#### Plan Execution
```yaml
- name: 'Terraform Plan'
```
- Generates execution plan
- Shows resources to be created/modified/destroyed
- Saved as artifact for audit trail

#### Plan Artifact Upload
```yaml
- name: 'Upload Plan Artifact'
```
- Stores plan file for 1 day
- Allows review even after deployment
- Enables audit trail

#### PR Comment
```yaml
- name: 'Comment Plan on Pull Request'
```
- Posts plan output as comment on PR (if triggered by PR)
- Shows team members what changes will happen
- Enables collaborative review

**Output**: Plan artifact and PR comment (if applicable)

---

### Stage 3: Terraform Apply (Manual Approval Required)

**Runs**: After plan succeeds, only on pushes to main
**Purpose**: Deploy infrastructure to production
**Requirement**: **Manual approval from designated reviewer**

**Approval Process**:

1. Push to main branch triggers pipeline
2. Validation and Plan stages run automatically
3. Deploy stage **pauses and waits** for approval
4. GitHub notifies reviewers: "Deployment waiting for approval"
5. Reviewer goes to Actions → Deploy job → Clicks "Approve and deploy"
6. Terraform Apply runs

**Steps**:

#### Pre-Apply Validation
```yaml
- name: 'Terraform Plan (Pre-Apply Validation)'
```
- Final check before destructive action
- Ensures nothing changed since plan
- Catches race conditions

#### Apply
```yaml
- name: 'Terraform Apply'
```
- Applies infrastructure changes
- Creates/updates/deletes Azure resources
- Only runs after manual approval

#### Output Capture
```yaml
- name: 'Capture Terraform Outputs'
```
- Gets all output values
- VM names, IPs, resource IDs
- Used for verification

**Output**: Deployment summary showing all created resources

---

### Stage 4: Post-Deployment Validation

**Runs**: After apply succeeds
**Purpose**: Verify infrastructure is actually operational

**Checks**:

#### Resource Group Verification
```yaml
- name: 'Verify Resource Group'
```
- Confirms resource group exists
- Accessible and properly configured

#### Virtual Machine Verification
```yaml
- name: 'Verify Virtual Machines'
```
- Checks both VMs are running
- Verifies VM status and power state
- Example:
  ```
  vm-test-1: VM running
  vm-test-2: VM running
  ```

#### Network Configuration Verification
```yaml
- name: 'Verify Network Configuration'
```
- Confirms Virtual Network exists
- Verifies subnet configuration
- Confirms NSG is in place

**Why This Stage?**: Deployment success ≠ infrastructure health. We verify the infrastructure actually works.

**Output**: Post-deployment summary with manual verification steps

---

## Pipeline Flow Diagram

```
Code Push to GitHub
       ↓
┌─────────────────────────────────────────────┐
│         STAGE 1: VALIDATION                 │
├─────────────────────────────────────────────┤
│ ✅ Format Check                              │
│ ✅ Backend Init                              │
│ ✅ Syntax Validation                         │
│ ✅ Security Scan (tfsec)                     │
│ ✅ Compliance Check (Checkov)                │
│ ✅ Publish Summary                           │
│                                              │
│ Status: All critical checks passed? → YES   │
└─────────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────────┐
│          STAGE 2: PLAN                      │
├─────────────────────────────────────────────┤
│ ✅ Generate Terraform Plan                   │
│ ✅ Upload Plan Artifact                      │
│ ✅ Comment Plan on PR (if PR)               │
│                                              │
│ Status: Plan succeeded? → YES                │
└─────────────────────────────────────────────┘
       ↓
   Is this a PR?
       ├─ YES → Stop (plan only)
       └─ NO → Continue to deployment
            ↓
┌─────────────────────────────────────────────┐
│ STAGE 3: DEPLOY (Manual Approval Required)  │
├─────────────────────────────────────────────┤
│ ⏸️  WAIT for Reviewer Approval              │
│    (GitHub notifies reviewers)              │
│                                              │
│ Human clicks "Approve and deploy"           │
│                                              │
│ ✅ Pre-Apply Validation                      │
│ ✅ Terraform Apply (Creates Resources)       │
│ ✅ Capture Outputs                           │
│ ✅ Publish Deployment Summary                │
│                                              │
│ Status: Resources created successfully      │
└─────────────────────────────────────────────┘
       ↓
┌─────────────────────────────────────────────┐
│    STAGE 4: POST-DEPLOYMENT VALIDATION      │
├─────────────────────────────────────────────┤
│ ✅ Verify Resource Group                     │
│ ✅ Verify Virtual Machines Running           │
│ ✅ Verify Network Configuration              │
│ ✅ Show Manual Verification Steps            │
│                                              │
│ Status: Infrastructure is Operational ✅    │
└─────────────────────────────────────────────┘
       ↓
 🎉 PIPELINE COMPLETE
```

---

## Environment Variables Management

### Workflow-Level (Shared, Non-Sensitive)
These are available to ALL jobs:
```yaml
env:
  TERRAFORM_VERSION: "~> 1.5"
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  AZURE_REGION: "eastus"
  RESOURCE_GROUP: "elekta-devops-test"
```

**Why**: Non-sensitive, needed across multiple jobs

### Job-Level (Restricted, Sensitive)
These are available only to specific jobs:

**Validate & Plan Jobs**:
```yaml
env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
```

**Deploy Job**:
```yaml
env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
  TF_VAR_admin_password: ${{ secrets.ADMIN_PASSWORD }}
```

**Why**: Principle of least privilege - each job only gets what it needs

---

## Deployment Process

### Automatic (Push to main)
```bash
# Make code changes
git add terraform/
git commit -m "Update infrastructure"
git push origin main

# Pipeline automatically:
# 1. Validates code
# 2. Plans changes
# 3. WAITS for approval
# 4. Applies changes (after approval)
# 5. Validates deployment
```

### Via Pull Request
```bash
# Create feature branch
git checkout -b feature/update-vm-size

# Make changes
git add terraform/
git commit -m "Increase VM size"
git push origin feature/update-vm-size

# Open PR on GitHub
# Pipeline automatically:
# 1. Validates code
# 2. Plans changes
# 3. Comments plan on PR
# 4. NO deployment (PRs don't deploy)

# After review and approval:
# Merge PR to main
# Deployment happens automatically (with approval gate)
```

### Manual Trigger
```bash
# Go to GitHub Actions tab
# Click "Terraform Deploy - Production Grade"
# Click "Run workflow"
# Select main branch
# Click "Run workflow"
```

---

## Accessing VMs via RDP

### From Your Machine to VM1

```
Host: <vm1_public_ip>
Username: Elekta
Password: ElektaDevopsTest123!
```

**Windows**: Press `Win + R`, type `mstsc`, enter IP
**Mac/Linux**: `rdesktop <vm1_public_ip> -u Elekta -p ElektaDevopsTest123!`

### From VM1 to VM2 (Internal Communication)

Once connected to VM1, open RDP and connect to VM2 using its **private IP**:

```
Host: <vm2_private_ip>  (e.g., 10.0.1.5)
Username: Elekta
Password: ElektaDevopsTest123!
```

This verifies inter-VM communication works correctly.

---

## Troubleshooting

### Pipeline Issues

#### Terraform Init Fails with "Storage Account Not Found"

**Cause**: Storage account name has uppercase letters or doesn't exist

**Solution**:
```bash
# Azure storage account names MUST be lowercase
# Check what exists:
az storage account list --resource-group rg-terraform-state --output table

# Create new one if needed (lowercase):
az storage account create \
  --name tfstatestgelekta \
  --resource-group rg-terraform-state \
  --location eastus \
  --sku Standard_LRS

# Update workflow file to use lowercase name
# In .github/workflows/terraform-deploy.yml:
# -backend-config="storage_account_name=tfstatestgelekta"
```

#### GitHub Actions: "Not Found" Error in Post Deployment

**Cause**: Trying to post comment on deployment (no issue number)

**Solution**: The workflow already handles this - comments only post on PRs, not on main pushes

#### Approval Gate Not Showing

**Cause**: Environment not configured or reviewers not added

**Solution**:
1. Go to **Settings → Environments → production**
2. Check "Required reviewers" is enabled
3. Add yourself as reviewer
4. Save

---

### Terraform Issues

#### Plan Shows Unexpected Changes

```bash
# Refresh state and replan
cd terraform
terraform refresh
terraform plan
```

#### State Lock Timeout

```bash
# If state is locked from failed apply
terraform force-unlock <LOCK_ID>

# Get lock ID from error message
```

#### Resource Already Exists

```bash
# Resource created outside Terraform
# Two options:
# 1. Import into Terraform:
terraform import azurerm_resource_group.main /subscriptions/SUB_ID/resourceGroups/rg-name

# 2. Or delete from Azure and reapply:
az group delete --name elekta-devops-test --yes
terraform apply
```

---

## File Locations Reference

| File/Directory | Purpose |
|---|---|
| `/usr/share/keyrings/hashicorp-archive-keyring.gpg` | HashiCorp's GPG public key |
| `/etc/apt/sources.list.d/hashicorp.list` | HashiCorp repository configuration |
| `/usr/bin/terraform` | Terraform executable (after install) |
| `.github/workflows/terraform-deploy.yml` | GitHub Actions pipeline definition |
| `terraform/main.tf` | Core infrastructure code |
| `terraform/variables.tf` | Variable definitions |
| `terraform/terraform.tfvars` | Variable values (secret - not in git) |
| `terraform/terraform.tfvars.example` | Template for terraform.tfvars |
| `.terraform/` | Terraform working directory |
| `tfplan` | Terraform plan file (saved during pipeline) |

---

## Security Considerations

### What's Secure ✅
- Credentials stored in GitHub Secrets (encrypted at rest)
- Terraform state encrypted in Azure Storage
- Service Principal limited to Contributor role
- Approval gate prevents accidental deployments
- Security scanning (tfsec) checks for misconfigurations
- Compliance checks (Checkov) validate standards

### What's NOT Production-Ready ⚠️
- RDP open to 0.0.0.0/0 (should restrict to your IP)
- Admin password is test value (use strong password in production)
- No monitoring/alerting configured
- No backup/disaster recovery strategy

### Production Recommendations

```hcl
# Restrict RDP to specific IP
variable "allowed_rdp_sources" {
  type    = list(string)
  default = ["YOUR_IP/32"]  # Your IP range
}

ingress_rule {
  source_address_prefix = var.allowed_rdp_sources[0]
}

# Use Azure Bastion for secure access
# Use managed identities instead of service principals
# Enable VM monitoring and alerts
# Implement backup policies
# Use managed disks with encryption
```

---

## Cost Management

**Estimated Monthly Cost**:
- Standard_B2s VM: ~$65 each = $130 for 2
- Storage Account: ~$2
- Public IPs: ~$3 each = $6 for 2
- **Total**: ~$138/month

**To Save Money**:
```bash
# Delete resources when not in use
terraform destroy

# Or stop VMs without deleting
az vm deallocate --name vm-test-1 --resource-group elekta-devops-test
```

---

## Cleanup

When assessment is complete:

```bash
# Destroy all resources
cd terraform
terraform destroy

# Confirm by typing 'yes' when prompted

# Optional: Delete resource group for state
az group delete --name rg-terraform-state --yes
```

This removes:
- VMs
- Networking
- Storage
- All associated resources

**Saves**: ~$138/month after cleanup

---

## Design Decisions

### Why Standard_LRS for State Storage?
Standard_LRS (Locally Redundant Storage) provides:
- ✅ Encryption at rest
- ✅ Automated backup within region
- ✅ Cost-effective for non-critical data
- ✅ Sufficient redundancy for state files

In production, consider GRS (Geo-Redundant Storage) for multi-region failover.

### Why Two Resource Groups?
- `rg-terraform-state`: Holds state backend (separate, protected)
- `elekta-devops-test`: Holds application infrastructure

**Why**: Separates infrastructure state from managed resources. State should be protected independently.

### Why Manual Approval for Deployment?
- Prevents accidental infrastructure changes
- Enables code review before deployment
- Provides audit trail of who deployed what and when
- Best practice for production environments

### Why Post-Deployment Validation?
- Verifies infrastructure is operational
- Catches configuration issues early
- Better than discovering issues during manual testing
- Enables automation of verification steps

---

## References

- [Terraform Official Website](https://www.terraform.io/)
- [HashiCorp Downloads](https://www.hashicorp.com/products/terraform/downloads)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure CLI Documentation](https://docs.microsoft.com/cli/azure/)
- [Terraform Best Practices](https://www.terraform.io/cloud-docs/recommended-practices)

---

## Related Resources

- [Infrastructure as Code Best Practices](https://learn.hashicorp.com/collections/terraform/cloud)
- [Azure Architecture Patterns](https://docs.microsoft.com/en-us/azure/architecture/)
- [DevOps Fundamentals](https://docs.microsoft.com/en-us/devops/)

---

**Document Created**: November 15, 2025  
**Last Updated**: November 21, 2025  
**Terraform Version**: 1.5.0+  
**Pipeline Version**: 4-Stage with Post-Deployment Validation  
**Assessment Level**: Senior DevOps Engineer

## References
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [GitHub Actions Terraform](https://github.com/hashicorp/setup-terraform)
- [Azure Terraform Backend](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)

---