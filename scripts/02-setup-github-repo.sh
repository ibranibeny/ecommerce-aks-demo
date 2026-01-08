#!/bin/bash
# GitHub Repository Setup Script

REPO_NAME="ecommerce-aks-demo"

echo "=========================================="
echo "GitHub Repository Setup"
echo "=========================================="

# Check gh CLI
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI not installed. Install from: https://cli.github.com/"
    exit 1
fi

# Check login
gh auth status || gh auth login

GITHUB_USER=$(gh api user --jq '.login')
echo "Logged in as: $GITHUB_USER"

# Create repo
echo "Creating GitHub repository: $REPO_NAME"
gh repo create $REPO_NAME --public --description "Ecommerce CI/CD demo with GitHub Actions and AKS" --clone=false

# Setup local git
cd "/mnt/c/Users/benyibrani/OneDrive - Microsoft/Documents/Learning/Workshop/GH-AKS"
git init 2>/dev/null
git remote remove origin 2>/dev/null
git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"

echo ""
echo "Repository created: https://github.com/$GITHUB_USER/$REPO_NAME"
echo ""
echo "Add these secrets using: gh secret set <SECRET_NAME>"
echo "- AZURE_CREDENTIALS"
echo "- ACR_LOGIN_SERVER"
echo "- ACR_NAME"
echo "- ACR_USERNAME" 
echo "- ACR_PASSWORD"
echo "- RESOURCE_GROUP"
echo "- AKS_CLUSTER_NAME"
