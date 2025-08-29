#!/bin/bash

ENV=${1:-dev}
echo "Deploying all services for environment: $ENV"

# List of all services
SERVICES=(
    "config-server"
    "api-server"
    "site-management-service"
    "shopping-service"
    "posts-service"
    "payment-gateway"
    "order-service"
    "notification-service"
    "loyalty-service"
    "inventory-service"
    "fazeal-business-management"
    "fazeal-business"
    "events-service"
    "angular-customer-ssr"
    "cron-jobs"
    "chat-app"
    "business-chat"
    "api-gateway"
    "angular-dev"
    "angular-customer"
    "angular-business"
    "angular-ads"
    "angular-employee"
    "album-service"
    "ads-service"
    "promotion-service"
    "catalog-service"
    "customer-service"
    "employees-service"
    "payment-service"
    "translation-service"
    "watermark-detection"
)

# Deploy all services
for service in "${SERVICES[@]}"; do
    echo "Deploying $service..."
    
    # Check if service directory exists
    if [ ! -d "application_deployment/$ENV/$service" ]; then
        echo "Warning: Directory for $service does not exist, skipping..."
        continue
    fi
    
    # Deploy ConfigMap
    if [ -f "application_deployment/$ENV/$service/configmap.yml" ]; then
        kubectl apply -f "application_deployment/$ENV/$service/configmap.yml"
    fi
    
    # Deploy Secret
    if [ -f "application_deployment/$ENV/$service/secret.yml" ]; then
        kubectl apply -f "application_deployment/$ENV/$service/secret.yml"
    fi
    
    # Deploy Service
    if [ -f "application_deployment/$ENV/$service/service.yml" ]; then
        kubectl apply -f "application_deployment/$ENV/$service/service.yml"
    fi
    
    # Deploy Deployment
    if [ -f "application_deployment/$ENV/$service/deployment.yml" ]; then
        kubectl apply -f "application_deployment/$ENV/$service/deployment.yml"
    fi
    
    echo "Completed $service"
done

echo "All services deployment completed!"
echo "Check status with: kubectl get pods" 