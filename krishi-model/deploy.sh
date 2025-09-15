#!/bin/bash

# Krishi Sahayak ML Server Deployment Script
# This script builds and deploys the ML server to Kubernetes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="krishi-sahayak/ml-server"
IMAGE_TAG="latest"
NAMESPACE="krishi-sahayak"
REGISTRY="${CONTAINER_REGISTRY:-gcr.io/my-gcp-project-id-12345}" # Use CONTAINER_REGISTRY env var or default replace my registry with yours link

echo -e "${BLUE}🚀 Starting Krishi Sahayak ML Server Deployment${NC}"

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed. Please install kubectl first.${NC}"
    exit 1
fi

# Check if docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if we're connected to a Kubernetes cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Not connected to a Kubernetes cluster. Please connect first.${NC}"
    exit 1
fi

echo -e "${YELLOW}📦 Building Docker image...${NC}"
docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo -e "${YELLOW}🏷️  Tagging image for registry...${NC}"
docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

echo -e "${YELLOW}📤 Pushing image to registry...${NC}"
docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}

echo -e "${YELLOW}🔧 Creating namespace...${NC}"
kubectl apply -f k8s/namespace.yaml

echo -e "${YELLOW}⚙️  Creating ConfigMap...${NC}"
kubectl apply -f k8s/configmap.yaml

echo -e "${YELLOW}🚀 Deploying ML server...${NC}"
kubectl apply -f k8s/deployment.yaml

echo -e "${YELLOW}🌐 Creating service...${NC}"
kubectl apply -f k8s/service.yaml

echo -e "${YELLOW}📈 Setting up auto-scaling...${NC}"
kubectl apply -f k8s/hpa.yaml

echo -e "${YELLOW}🔗 Creating ingress...${NC}"
kubectl apply -f k8s/ingress.yaml

echo -e "${YELLOW}⏳ Waiting for deployment to be ready...${NC}"
kubectl wait --for=condition=available --timeout=300s deployment/ml-server -n ${NAMESPACE}

echo -e "${GREEN}✅ Deployment completed successfully!${NC}"

echo -e "${BLUE}📊 Deployment Status:${NC}"
kubectl get pods -n ${NAMESPACE}
kubectl get services -n ${NAMESPACE}
kubectl get ingress -n ${NAMESPACE}

echo -e "${BLUE}🔍 To check logs:${NC}"
echo "kubectl logs -f deployment/ml-server -n ${NAMESPACE}"

echo -e "${BLUE}🌐 To access the service:${NC}"
echo "kubectl port-forward service/ml-server-service 8080:80 -n ${NAMESPACE}"

echo -e "${GREEN}🎉 Krishi Sahayak ML Server is now running in Kubernetes!${NC}"
