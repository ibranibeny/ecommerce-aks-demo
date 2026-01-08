#!/bin/bash
# AKS Landing Zone Setup Script - Indonesia Central

RESOURCE_GROUP="rg-ecommerce-demo"
LOCATION="indonesiacentral"
AKS_CLUSTER_NAME="aks-ecommerce-demo"
ACR_NAME="acrecommercedemo$(openssl rand -hex 4)"
NODE_COUNT=2
NODE_VM_SIZE="Standard_B2s"

echo "=========================================="
echo "AKS Landing Zone Setup - Indonesia Central"
echo "=========================================="

# Login check
az account show > /dev/null 2>&1 || az login

# Register providers
echo "Registering Azure providers..."
az provider register --namespace Microsoft.ContainerService --wait
az provider register --namespace Microsoft.ContainerRegistry --wait

# Create Resource Group
echo "Creating Resource Group: $RESOURCE_GROUP"
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create ACR
echo "Creating ACR: $ACR_NAME"
az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic --admin-enabled true

# Create AKS
echo "Creating AKS: $AKS_CLUSTER_NAME (this takes 5-10 minutes)..."
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_CLUSTER_NAME \
    --node-count $NODE_COUNT \
    --node-vm-size $NODE_VM_SIZE \
    --enable-managed-identity \
    --attach-acr $ACR_NAME \
    --generate-ssh-keys

# Get credentials
echo "Getting AKS credentials..."
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing

# Install NGINX Ingress
echo "Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml

# Create namespace
kubectl create namespace ecommerce-app

# Get ACR credentials
ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer -o tsv)
ACR_USERNAME=$(az acr credential show --name $ACR_NAME --query username -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query passwords[0].value -o tsv)

# Create service principal for GitHub Actions
echo "Creating Service Principal..."
SP_JSON=$(az ad sp create-for-rbac --name "sp-github-ecommerce" --role contributor \
    --scopes /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP --sdk-auth)

echo ""
echo "=========================================="
echo "SAVE THESE VALUES FOR GITHUB SECRETS:"
echo "=========================================="
echo ""
echo "AZURE_CREDENTIALS:"
echo "$SP_JSON"
echo ""
echo "ACR_LOGIN_SERVER: $ACR_LOGIN_SERVER"
echo "ACR_NAME: $ACR_NAME"
echo "ACR_USERNAME: $ACR_USERNAME"
echo "ACR_PASSWORD: $ACR_PASSWORD"
echo "RESOURCE_GROUP: $RESOURCE_GROUP"
echo "AKS_CLUSTER_NAME: $AKS_CLUSTER_NAME"
echo "=========================================="
