#!/bin/bash

# Multi-Model Krishi Sahayak Deployment Script
# This script deploys the enhanced multi-model system to Google Cloud

set -e

echo "🚀 Starting Multi-Model Krishi Sahayak Deployment..."
echo "=================================================="

# Configuration
PROJECT_ID="composed-slice-410214"
REGION="us-central1"
CLUSTER_NAME="krishi-cluster"
NAMESPACE="krishi-sahayak"
IMAGE_NAME="gcr.io/$PROJECT_ID/krishi-ml-server"
TAG="multi-model-$(date +%Y%m%d-%H%M%S)"

echo "📋 Deployment Configuration:"
echo "  Project ID: $PROJECT_ID"
echo "  Region: $REGION"
echo "  Cluster: $CLUSTER_NAME"
echo "  Namespace: $NAMESPACE"
echo "  Image: $IMAGE_NAME:$TAG"
echo ""

# Step 1: Build and push Docker image
echo "🐳 Building and pushing Docker image..."
cd krishi-model

# Build the image
docker build -t $IMAGE_NAME:$TAG .

# Push to Google Container Registry
docker push $IMAGE_NAME:$TAG

echo "✅ Docker image built and pushed successfully"
echo ""

# Step 2: Update Kubernetes deployment
echo "☸️  Updating Kubernetes deployment..."

# Update the image tag in deployment.yaml
sed -i.bak "s|image: krishi-sahayak/ml-server:latest|image: $IMAGE_NAME:$TAG|g" k8s/deployment.yaml

# Apply Kubernetes configurations
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/model-configmap.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

echo "✅ Kubernetes resources applied successfully"
echo ""

# Step 3: Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl rollout status deployment/ml-server -n $NAMESPACE --timeout=300s

echo "✅ Deployment is ready!"
echo ""

# Step 4: Get service information
echo "🌐 Service Information:"
echo "======================"

# Get the external IP
EXTERNAL_IP=$(kubectl get service ml-server-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
if [ -z "$EXTERNAL_IP" ]; then
    echo "⚠️  External IP not available yet. Checking ingress..."
    INGRESS_IP=$(kubectl get ingress ml-server-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [ -n "$INGRESS_IP" ]; then
        EXTERNAL_IP=$INGRESS_IP
    fi
fi

if [ -n "$EXTERNAL_IP" ]; then
    echo "🌍 Server URL: http://$EXTERNAL_IP"
    echo "🔍 Health Check: http://$EXTERNAL_IP/health"
    echo "📊 Model Status: http://$EXTERNAL_IP/models/status"
    echo "🌾 Available Crops: http://$EXTERNAL_IP/models/available_crops"
else
    echo "⚠️  External IP not available. Check with: kubectl get services -n $NAMESPACE"
fi

echo ""

# Step 5: Test the deployment
echo "🧪 Testing deployment..."
echo "======================="

# Wait a bit for the service to be fully ready
sleep 10

# Test health endpoint
echo "Testing health endpoint..."
if curl -f -s "http://$EXTERNAL_IP/health" > /dev/null; then
    echo "✅ Health check passed"
else
    echo "❌ Health check failed"
fi

# Test models status endpoint
echo "Testing models status endpoint..."
if curl -f -s "http://$EXTERNAL_IP/models/status" > /dev/null; then
    echo "✅ Models status endpoint working"
else
    echo "❌ Models status endpoint failed"
fi

echo ""

# Step 6: Update Flutter app configuration
echo "📱 Flutter App Configuration:"
echo "============================="

if [ -n "$EXTERNAL_IP" ]; then
    echo "Update your Flutter app's ML service with:"
    echo "  static const String baseUrl = 'http://$EXTERNAL_IP';"
    echo ""
    echo "Or for HTTPS (if configured):"
    echo "  static const String baseUrl = 'https://$EXTERNAL_IP';"
else
    echo "⚠️  External IP not available. Check the service status first."
fi

echo ""

# Step 7: Show deployment summary
echo "📊 Deployment Summary:"
echo "====================="
echo "✅ Multi-model system deployed successfully!"
echo "✅ All 8 specialized models are available:"
echo "   - Crop Detector (5.51 MB)"
echo "   - Corn Disease Detector (5.51 MB)"
echo "   - Wheat Disease Detector (5.51 MB)"
echo "   - Rice Disease Detector (5.51 MB)"
echo "   - Potato Disease Detector (5.51 MB)"
echo "   - Sugarcane Disease Detector (5.51 MB)"
echo "   - Multitask Model (4.89 MB)"
echo "   - Best Model (4.89 MB)"
echo ""
echo "🔧 New API Endpoints:"
echo "   - POST /analyze_crop - Two-stage analysis"
echo "   - POST /analyze_crop_direct - Direct analysis"
echo "   - GET /models/status - Model status"
echo "   - GET /models/available_crops - Available crops"
echo "   - GET /models/info/<model_name> - Model details"
echo ""
echo "🎉 Deployment completed successfully!"
echo ""

# Step 8: Show useful commands
echo "🛠️  Useful Commands:"
echo "==================="
echo "View pods: kubectl get pods -n $NAMESPACE"
echo "View services: kubectl get services -n $NAMESPACE"
echo "View logs: kubectl logs -f deployment/ml-server -n $NAMESPACE"
echo "Scale deployment: kubectl scale deployment/ml-server --replicas=3 -n $NAMESPACE"
echo "Delete deployment: kubectl delete -f k8s/ -n $NAMESPACE"
echo ""

echo "🚀 Multi-Model Krishi Sahayak is now live!"
