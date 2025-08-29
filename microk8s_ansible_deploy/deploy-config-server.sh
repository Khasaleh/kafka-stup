#!/bin/bash

echo "Deploying Config Server..."

# Deploy ConfigMap
echo "Deploying ConfigMap..."
kubectl apply -f application_deployment/dev/config-server/configmap.yml

# Deploy Secret
echo "Deploying Secret..."
kubectl apply -f application_deployment/dev/config-server/secret.yml

# Deploy Service
echo "Deploying Service..."
kubectl apply -f application_deployment/dev/config-server/service.yml

# Deploy Deployment
echo "Deploying Deployment..."
kubectl apply -f application_deployment/dev/config-server/deployment.yml

echo "Config Server deployment completed!"
echo "Check status with: kubectl get pods | grep config-server" 