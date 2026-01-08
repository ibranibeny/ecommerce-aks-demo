# Deployment Guide: CI/CD Pipeline with GitHub Actions and Azure Kubernetes Service

This document provides step-by-step instructions for deploying the ShopHub ecommerce application to Azure Kubernetes Service (AKS) using GitHub Actions for continuous integration and continuous deployment.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Phase 1: Azure Infrastructure Setup](#phase-1-azure-infrastructure-setup)
3. [Phase 2: GitHub Repository Configuration](#phase-2-github-repository-configuration)
4. [Phase 3: GitHub Secrets Configuration](#phase-3-github-secrets-configuration)
5. [Phase 4: Trigger CI/CD Pipeline](#phase-4-trigger-cicd-pipeline)
6. [Phase 5: Verify Deployment](#phase-5-verify-deployment)
7. [Troubleshooting](#troubleshooting)
8. [Cleanup](#cleanup)

---

## Prerequisites

Ensure the following tools are installed and configured on your local machine:

| Tool | Purpose | Installation |
|------|---------|--------------|
| Azure CLI | Manage Azure resources | `curl -sL https://aka.ms/InstallAzureCLIDeb \| sudo bash` |
| GitHub CLI | Manage GitHub repositories | `sudo apt install gh` |
| kubectl | Manage Kubernetes clusters | `az aks install-cli` |
| Docker | Build container images | Install Docker Desktop or Docker Engine |

Verify installations:

```bash
az --version
gh --version
kubectl version --client
docker --version
```

---

## Phase 1: Azure Infrastructure Setup

### Step 1.1: Login to Azure

```bash
az login
```

### Step 1.2: Set Variables

```bash
export RESOURCE_GROUP="rg-ecommerce-demo"
export LOCATION="indonesiacentral"
export AKS_CLUSTER_NAME="aks-ecommerce-demo"
export ACR_NAME="acrecommercedemo$(openssl rand -hex 4)"
```

### Step 1.3: Register Required Providers

```bash
az provider register --namespace Microsoft.ContainerService --wait
az provider register --namespace Microsoft.ContainerRegistry --wait
```

### Step 1.4: Create Resource Group

```bash
az group create --name $RESOURCE_GROUP --location $LOCATION
```

### Step 1.5: Create Azure Container Registry

```bash
az acr create \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --sku Basic \
    --admin-enabled true
```

### Step 1.6: Create AKS Cluster

This step takes approximately 5-10 minutes.

```bash
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --node-count 2 \
    --node-vm-size Standard_B2s \
    --enable-managed-identity \
    --attach-acr $ACR_NAME \
    --generate-ssh-keys \
    --location $LOCATION
```

### Step 1.7: Get AKS Credentials

```bash
az aks get-credentials \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --overwrite-existing
```

### Step 1.8: Verify Cluster Nodes

```bash
kubectl get nodes
```

Expected output shows 2 nodes in Ready status.

### Step 1.9: Install NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml
```

### Step 1.10: Create Application Namespace

```bash
kubectl create namespace ecommerce-app
```

---

## Phase 2: GitHub Repository Configuration

### Step 2.1: Authenticate GitHub CLI

```bash
gh auth login
```

Follow the prompts to authenticate with your GitHub account.

### Step 2.2: Create GitHub Repository

```bash
gh repo create ecommerce-aks-demo --public --source=. --remote=origin --push
```

### Step 2.3: Verify Repository Creation

```bash
gh repo view --web
```

---

## Phase 3: GitHub Secrets Configuration

### Step 3.1: Retrieve ACR Credentials

```bash
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)

echo "ACR_LOGIN_SERVER: $ACR_LOGIN_SERVER"
echo "ACR_USERNAME: $ACR_USERNAME"
echo "ACR_PASSWORD: $ACR_PASSWORD"
```

### Step 3.2: Create Service Principal for GitHub Actions

```bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

az ad sp create-for-rbac \
    --name "sp-github-ecommerce" \
    --role contributor \
    --scopes /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP \
    --sdk-auth
```

Save the JSON output for the AZURE_CREDENTIALS secret.

### Step 3.3: Configure GitHub Secrets

Add the following secrets to your GitHub repository:

```bash
gh secret set AZURE_CREDENTIALS --body '<paste-service-principal-json>'
gh secret set ACR_LOGIN_SERVER --body "$ACR_LOGIN_SERVER"
gh secret set ACR_USERNAME --body "$ACR_USERNAME"
gh secret set ACR_PASSWORD --body "$ACR_PASSWORD"
gh secret set RESOURCE_GROUP --body "$RESOURCE_GROUP"
gh secret set AKS_CLUSTER_NAME --body "$AKS_CLUSTER_NAME"
```

### Step 3.4: Verify Secrets

```bash
gh secret list
```

Expected output shows all 6 secrets configured.

---

## Phase 4: Trigger CI/CD Pipeline

### Step 4.1: Generate Package Lock File

```bash
npm install
```

### Step 4.2: Commit and Push Changes

```bash
git add .
git commit -m "Add package-lock.json for CI/CD"
git push origin master
```

### Step 4.3: Monitor Pipeline Execution

```bash
gh run watch
```

Alternatively, view in browser:

```bash
gh run list --web
```

### Step 4.4: Manual Pipeline Trigger (Optional)

```bash
gh workflow run ci-cd.yaml
```

---

## Phase 5: Verify Deployment

### Step 5.1: Check Pod Status

```bash
kubectl get pods -n ecommerce-app
```

Expected output shows pods in Running status.

### Step 5.2: Check Service Status

```bash
kubectl get svc -n ecommerce-app
```

### Step 5.3: Get Ingress External IP

```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller \
    -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Step 5.4: Access Application

Open browser and navigate to the external IP address obtained in the previous step.

### Step 5.5: View Application Logs

```bash
kubectl logs -f deployment/ecommerce-app -n ecommerce-app
```

---

## Troubleshooting

### Issue: Pipeline Fails at npm ci

Cause: Missing package-lock.json file.

Solution:
```bash
npm install
git add package-lock.json
git commit -m "Add package-lock.json"
git push
```

### Issue: Docker Build Fails

Cause: Incorrect Dockerfile syntax or missing files.

Solution: Verify Dockerfile and ensure all required files are present in the repository.

### Issue: Deployment Fails with ImagePullBackOff

Cause: AKS cannot pull image from ACR.

Solution: Verify ACR is attached to AKS:
```bash
az aks update \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --attach-acr $ACR_NAME
```

### Issue: Pods Not Starting

Cause: Resource limits or configuration issues.

Solution: Check pod events:
```bash
kubectl describe pod <pod-name> -n ecommerce-app
```

### Issue: Ingress Not Working

Cause: NGINX Ingress Controller not installed or misconfigured.

Solution: Verify ingress controller is running:
```bash
kubectl get pods -n ingress-nginx
```

---

## Cleanup

To remove all Azure resources created during this deployment:

### Option 1: Delete Resource Group (Recommended)

This removes all resources including AKS, ACR, and networking components.

```bash
az group delete --name rg-ecommerce-demo --yes --no-wait
```

### Option 2: Delete Individual Resources

```bash
# Delete AKS Cluster
az aks delete \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --yes --no-wait

# Delete ACR
az acr delete \
    --resource-group $RESOURCE_GROUP \
    --name $ACR_NAME \
    --yes

# Delete Service Principal
az ad sp delete --id $(az ad sp list --display-name "sp-github-ecommerce" --query [0].appId -o tsv)

# Delete Resource Group
az group delete --name $RESOURCE_GROUP --yes --no-wait
```

### Delete GitHub Repository (Optional)

```bash
gh repo delete ibranibeny/ecommerce-aks-demo --yes
```

---

## Summary

| Phase | Description | Status |
|-------|-------------|--------|
| Phase 1 | Azure Infrastructure Setup | Complete |
| Phase 2 | GitHub Repository Configuration | Complete |
| Phase 3 | GitHub Secrets Configuration | Complete |
| Phase 4 | CI/CD Pipeline Trigger | Complete |
| Phase 5 | Deployment Verification | Complete |

---

## References

- Azure Kubernetes Service Documentation: https://docs.microsoft.com/azure/aks/
- GitHub Actions Documentation: https://docs.github.com/actions
- NGINX Ingress Controller: https://kubernetes.github.io/ingress-nginx/
- Azure Container Registry: https://docs.microsoft.com/azure/container-registry/

---

Document Version: 1.0  
Last Updated: January 2026
