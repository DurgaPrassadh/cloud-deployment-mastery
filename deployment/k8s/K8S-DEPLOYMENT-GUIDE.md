# Kubernetes Deployment Guide

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS EKS Cluster                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                     │
│  │   Ingress       │    │  AWS ALB        │                     │
│  │   Controller    │────│  (Internet)     │                     │
│  └────────┬────────┘    └─────────────────┘                     │
│           │                                                      │
│  ┌────────▼────────┐                                            │
│  │   Frontend      │  ← ClusterIP Service                       │
│  │   Deployment    │    (2-5 replicas with HPA)                 │
│  │   (Nginx)       │                                            │
│  └────────┬────────┘                                            │
│           │                                                      │
│  ┌────────▼────────┐                                            │
│  │   Backend API   │  ← ClusterIP Service                       │
│  │   Deployment    │    (2-10 replicas with HPA)                │
│  │   (Node.js)     │                                            │
│  └────────┬────────┘                                            │
│           │ (Network Policy)                                     │
│  ┌────────▼────────┐                                            │
│  │   PostgreSQL    │  ← ClusterIP Service (Internal Only)       │
│  │   StatefulSet   │    (1 replica with PVC)                    │
│  │   (Database)    │                                            │
│  └─────────────────┘                                            │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- kubectl installed
- eksctl installed (for EKS cluster creation)
- Docker installed (for building images)
- Helm installed (for installing add-ons)

## Step 1: Create EKS Cluster

```bash
# Using eksctl with the provided config
eksctl create cluster -f deployment/k8s/aws-eks/eks-cluster.yaml

# Verify cluster is running
kubectl get nodes
```

## Step 2: Install Required Add-ons

### Install AWS Load Balancer Controller
```bash
# Add the EKS chart repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Install the controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=devops-dashboard-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### Install NGINX Ingress Controller (Alternative)
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace
```

### Install Cert-Manager (for SSL)
```bash
helm repo add jetstack https://charts.jetstack.io
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true
```

## Step 3: Build and Push Docker Images

```bash
# Login to ECR
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com

# Create ECR repositories
aws ecr create-repository --repository-name devops-dashboard-frontend
aws ecr create-repository --repository-name devops-dashboard-backend

# Build and push frontend
docker build -t devops-dashboard-frontend .
docker tag devops-dashboard-frontend:latest ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/devops-dashboard-frontend:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/devops-dashboard-frontend:latest

# Build and push backend
docker build -t devops-dashboard-backend -f deployment/backend/Dockerfile .
docker tag devops-dashboard-backend:latest ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/devops-dashboard-backend:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com/devops-dashboard-backend:latest
```

## Step 4: Create ECR Pull Secret

```bash
kubectl create namespace devops-dashboard

kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=${AWS_ACCOUNT_ID}.dkr.ecr.ap-south-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region ap-south-1) \
  --namespace=devops-dashboard
```

## Step 5: Deploy Application

### Update image references
Before deploying, update the image references in the deployment files:
```bash
# Replace placeholder with actual AWS account ID
export AWS_ACCOUNT_ID=your-account-id
export AWS_REGION=ap-south-1

# Update deployment files
sed -i "s/\${AWS_ACCOUNT_ID}/${AWS_ACCOUNT_ID}/g" deployment/k8s/backend/backend-deployment.yaml
sed -i "s/\${AWS_REGION}/${AWS_REGION}/g" deployment/k8s/backend/backend-deployment.yaml
sed -i "s/\${AWS_ACCOUNT_ID}/${AWS_ACCOUNT_ID}/g" deployment/k8s/frontend/frontend-deployment.yaml
sed -i "s/\${AWS_REGION}/${AWS_REGION}/g" deployment/k8s/frontend/frontend-deployment.yaml
```

### Deploy in order
```bash
# 1. Create namespace
kubectl apply -f deployment/k8s/namespace.yaml

# 2. Apply configs and secrets
kubectl apply -f deployment/k8s/configmap.yaml
kubectl apply -f deployment/k8s/secrets.yaml

# 3. Deploy database
kubectl apply -f deployment/k8s/database/

# 4. Wait for database to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n devops-dashboard --timeout=120s

# 5. Deploy backend
kubectl apply -f deployment/k8s/backend/

# 6. Wait for backend to be ready
kubectl wait --for=condition=ready pod -l app=backend-api -n devops-dashboard --timeout=120s

# 7. Deploy frontend
kubectl apply -f deployment/k8s/frontend/

# 8. Apply network policies
kubectl apply -f deployment/k8s/network-policies/

# 9. Deploy ingress
kubectl apply -f deployment/k8s/ingress/ingress.yaml
```

## Step 6: Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n devops-dashboard

# Check services
kubectl get svc -n devops-dashboard

# Check ingress
kubectl get ingress -n devops-dashboard

# Check HPA status
kubectl get hpa -n devops-dashboard

# View logs
kubectl logs -l app=backend-api -n devops-dashboard --tail=100
kubectl logs -l app=frontend -n devops-dashboard --tail=100
```

## Step 7: Configure DNS

Get the Load Balancer address:
```bash
kubectl get ingress devops-dashboard-alb-ingress -n devops-dashboard -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

Create a CNAME record in Route53 or your DNS provider pointing to the ALB hostname.

## Useful Commands

### Scaling
```bash
# Manual scaling
kubectl scale deployment frontend --replicas=3 -n devops-dashboard
kubectl scale deployment backend-api --replicas=4 -n devops-dashboard

# View HPA status
kubectl get hpa -n devops-dashboard -w
```

### Updating Deployments
```bash
# Update image
kubectl set image deployment/frontend frontend=${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/devops-dashboard-frontend:v1.1.0 -n devops-dashboard

# Rollback
kubectl rollout undo deployment/frontend -n devops-dashboard

# Check rollout status
kubectl rollout status deployment/frontend -n devops-dashboard
```

### Debugging
```bash
# Get pod details
kubectl describe pod <pod-name> -n devops-dashboard

# Execute into pod
kubectl exec -it <pod-name> -n devops-dashboard -- /bin/sh

# Port forward for local testing
kubectl port-forward svc/backend-service 3000:3000 -n devops-dashboard
kubectl port-forward svc/frontend-service 8080:80 -n devops-dashboard
```

### Cleanup
```bash
# Delete all resources
kubectl delete namespace devops-dashboard

# Delete EKS cluster
eksctl delete cluster --name devops-dashboard-cluster
```

## Production Considerations

1. **Use AWS RDS instead of PostgreSQL pod** for production databases
2. **Enable cluster autoscaler** for automatic node scaling
3. **Configure PodDisruptionBudgets** for high availability
4. **Set up monitoring** with Prometheus and Grafana
5. **Configure backup** for persistent volumes
6. **Use AWS Secrets Manager** for sensitive data
7. **Enable audit logging** for compliance
8. **Set resource quotas** per namespace
