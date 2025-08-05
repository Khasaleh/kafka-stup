#!/bin/bash

# Test script for Ingress Controller deployment

echo "Testing Ingress Controller deployment..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Not connected to a Kubernetes cluster"
    exit 1
fi

echo "✓ Connected to cluster: $(kubectl config current-context)"

# Deploy ingress controller
echo "Deploying Ingress Controller..."
kubectl apply -f ingress-controller.yml

# Wait for deployment
echo "Waiting for Ingress Controller to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/ingress-nginx-controller

# Check status
echo ""
echo "Ingress Controller Status:"
kubectl get pods -l app.kubernetes.io/name=ingress-nginx
kubectl get services -l app.kubernetes.io/name=ingress-nginx
kubectl get ingressclass nginx

echo ""
echo "✓ Ingress Controller deployment test completed!" 