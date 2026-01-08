# 🛒 ShopHub - CI/CD Demo with GitHub Actions & AKS

A simple ecommerce Node.js application demonstrating CI/CD pipeline using GitHub Actions for deployment to Azure Kubernetes Service (AKS).

## 📋 Architecture Overview

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│   GitHub Repo   │─────▶│  GitHub Actions │─────▶│  Azure ACR      │
│   (Source)      │      │  (CI/CD)        │      │  (Container)    │
└─────────────────┘      └─────────────────┘      └────────┬────────┘
                                                           │
                                                           ▼
                         ┌─────────────────────────────────────────┐
                         │        Azure Kubernetes Service         │
                         │  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
                         │  │ Pod 1   │  │ Pod 2   │  │ Ingress │  │
                         │  └─────────┘  └─────────┘  └────┬────┘  │
                         └─────────────────────────────────┼───────┘
                                                           │
                                                           ▼
                                                    🌐 Users
```

## 🚀 Quick Start

### Prerequisites

- Azure CLI installed and logged in
- GitHub CLI installed (`gh`)
- kubectl installed
- Docker installed

### Step 1: Setup Azure Infrastructure

```bash
chmod +x scripts/*.sh
./scripts/01-setup-aks.sh
```

This creates:
- Resource Group: `rg-ecommerce-demo`
- Azure Container Registry
- AKS Cluster with 2 nodes (Standard_B2s) in Indonesia Central
- NGINX Ingress Controller
- Service Principal for GitHub Actions

### Step 2: Create GitHub Repository

```bash
./scripts/02-setup-github-repo.sh
```

### Step 3: Configure GitHub Secrets

Add the following secrets to your GitHub repository:

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | Service Principal JSON |
| `ACR_LOGIN_SERVER` | ACR URL (e.g., acrecommerce.azurecr.io) |
| `ACR_USERNAME` | ACR admin username |
| `ACR_PASSWORD` | ACR admin password |
| `RESOURCE_GROUP` | `rg-ecommerce-demo` |
| `AKS_CLUSTER_NAME` | `aks-ecommerce-demo` |

### Step 4: Push Code and Trigger CI/CD

```bash
git add .
git commit -m "Initial commit"
git push -u origin main
```

## 📁 Project Structure

```
├── src/
│   ├── server.js           # Express.js application
│   └── views/
│       ├── index.ejs       # Landing page
│       ├── product.ejs     # Product detail page
│       └── 404.ejs         # Error page
├── k8s/
│   ├── namespace.yaml      # Kubernetes namespace
│   ├── deployment.yaml     # Deployment configuration
│   ├── service.yaml        # ClusterIP service
│   └── ingress.yaml        # NGINX ingress
├── scripts/
│   ├── 01-setup-aks.sh     # Azure infrastructure setup
│   ├── 02-setup-github-repo.sh  # GitHub repo setup
│   └── 03-connect-aks.sh   # Connect to AKS
├── .github/
│   └── workflows/
│       └── ci-cd.yaml      # GitHub Actions pipeline
├── Dockerfile              # Multi-stage Docker build
└── package.json
```

## 🔄 CI/CD Pipeline

The pipeline is triggered on:
- Push to `main` branch
- Pull requests to `main`
- Manual workflow dispatch

### Pipeline Jobs

1. **Build & Test**: Installs dependencies and runs tests
2. **Build & Push**: Builds Docker image and pushes to ACR
3. **Deploy to AKS**: Applies Kubernetes manifests

## 🔧 Local Development

```bash
# Install dependencies
npm install

# Run in development mode
npm run dev

# Run tests
npm test

# Build Docker image
docker build -t ecommerce-app .

# Run with Docker
docker run -p 3000:3000 ecommerce-app
```

## 📊 Monitoring

### View Application Logs
```bash
kubectl logs -f deployment/ecommerce-app -n ecommerce-app
```

### Get Ingress IP
```bash
kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### Check Pod Status
```bash
kubectl get pods -n ecommerce-app
```

## 🧹 Cleanup

```bash
# Delete all Azure resources
az group delete --name rg-ecommerce-demo --yes --no-wait
```

## 🛠 Tech Stack

- **Runtime**: Node.js 20
- **Framework**: Express.js
- **Template Engine**: EJS
- **Container**: Docker (Alpine)
- **Orchestration**: Kubernetes (AKS)
- **Registry**: Azure Container Registry
- **CI/CD**: GitHub Actions
- **Ingress**: NGINX Ingress Controller

## 📝 License

MIT License - feel free to use for demos and learning!
