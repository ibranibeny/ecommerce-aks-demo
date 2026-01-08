#!/bin/bash
# Connect to AKS Cluster

RESOURCE_GROUP="${1:-rg-ecommerce-demo}"
AKS_CLUSTER_NAME="${2:-aks-ecommerce-demo}"

echo "Connecting to AKS: $AKS_CLUSTER_NAME"
az account show > /dev/null 2>&1 || az login

az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing

echo "Testing connection..."
kubectl cluster-info
kubectl get nodes
