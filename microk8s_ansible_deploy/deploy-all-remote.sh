#!/bin/bash

# Deployment script for remote server
# This script will deploy all services using kubectl

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

# Function to deploy a service
deploy_service() {
    local service="$1"
    local service_dir="application_deployment/$ENV/$service"
    
    echo "Deploying $service..."
    
    # Check if service directory exists
    if [ ! -d "$service_dir" ]; then
        echo "Warning: Directory for $service does not exist, skipping..."
        return 1
    fi
    
    # Deploy ConfigMap
    if [ -f "$service_dir/configmap.yml" ]; then
        echo "  - Deploying ConfigMap..."
        kubectl apply -f "$service_dir/configmap.yml"
        if [ $? -ne 0 ]; then
            echo "    Error: Failed to deploy ConfigMap for $service"
            return 1
        fi
    else
        echo "  - Warning: ConfigMap file not found for $service"
    fi
    
    # Deploy Secret
    if [ -f "$service_dir/secret.yml" ]; then
        echo "  - Deploying Secret..."
        kubectl apply -f "$service_dir/secret.yml"
        if [ $? -ne 0 ]; then
            echo "    Error: Failed to deploy Secret for $service"
            return 1
        fi
    else
        echo "  - Warning: Secret file not found for $service"
    fi
    
    # Deploy Service
    if [ -f "$service_dir/service.yml" ]; then
        echo "  - Deploying Service..."
        kubectl apply -f "$service_dir/service.yml"
        if [ $? -ne 0 ]; then
            echo "    Error: Failed to deploy Service for $service"
            return 1
        fi
    else
        echo "  - Warning: Service file not found for $service"
    fi
    
    # Deploy Deployment
    if [ -f "$service_dir/deployment.yml" ]; then
        echo "  - Deploying Deployment..."
        kubectl apply -f "$service_dir/deployment.yml"
        if [ $? -ne 0 ]; then
            echo "    Error: Failed to deploy Deployment for $service"
            return 1
        fi
    else
        echo "  - Warning: Deployment file not found for $service"
    fi
    
    echo "  ✓ Completed $service"
    return 0
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we're connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Not connected to a Kubernetes cluster"
    echo "Please ensure kubectl is configured properly"
    exit 1
fi

echo "Connected to cluster: $(kubectl config current-context)"
echo "Starting deployment of ${#SERVICES[@]} services..."

# Deploy all services
success_count=0
failed_services=()

for service in "${SERVICES[@]}"; do
    if deploy_service "$service"; then
        ((success_count++))
    else
        failed_services+=("$service")
    fi
    echo ""
done

# Summary
echo "=========================================="
echo "Deployment Summary:"
echo "=========================================="
echo "Total services: ${#SERVICES[@]}"
echo "Successfully deployed: $success_count"
echo "Failed: ${#failed_services[@]}"

if [ ${#failed_services[@]} -gt 0 ]; then
    echo "Failed services:"
    for service in "${failed_services[@]}"; do
        echo "  - $service"
    done
    echo ""
    echo "To retry failed services, run:"
    echo "  kubectl apply -f application_deployment/$ENV/<service-name>/"
fi

echo ""
echo "Check deployment status with:"
echo "  kubectl get pods"
echo "  kubectl get services"
echo "  kubectl get configmaps"
echo "  kubectl get secrets" 