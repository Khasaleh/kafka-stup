#!/bin/bash

# Full Deployment Script for MicroK8s Cluster
# This script handles the complete deployment including Elastic Stack, Ingress, and all services

set -e  # Exit on any error

# Configuration
ENV=${1:-dev}
IMAGE_TAG=${2:-latest}
NAMESPACE=${3:-default}

echo "=========================================="
echo "Full Deployment Script"
echo "=========================================="
echo "Environment: $ENV"
echo "Image Tag: $IMAGE_TAG"
echo "Namespace: $NAMESPACE"
echo "=========================================="

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "Error: kubectl is not installed or not in PATH"
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        echo "Error: Not connected to a Kubernetes cluster"
        exit 1
    fi
    
    echo "✓ Connected to cluster: $(kubectl config current-context)"
}

# Function to clean up old deployments
cleanup_old_deployments() {
    echo "Cleaning up old deployments..."
    
    # List of resources to clean up
    local resources=(
        "deployments"
        "services" 
        "configmaps"
        "secrets"
        "ingresses"
        "ingressclasses"
        "validatingwebhookconfigurations"
        "clusterroles"
        "clusterrolebindings"
        "roles"
        "rolebindings"
        "serviceaccounts"
        "jobs"
    )
    
    for resource in "${resources[@]}"; do
        echo "  - Cleaning up $resource..."
        kubectl delete $resource --all -n $NAMESPACE --ignore-not-found=true || true
    done
    
    # Clean up cluster-wide resources
    echo "  - Cleaning up cluster-wide resources..."
    kubectl delete clusterrole,clusterrolebinding --selector=app.kubernetes.io/name=ingress-nginx --ignore-not-found=true || true
    kubectl delete validatingwebhookconfiguration --selector=app.kubernetes.io/name=ingress-nginx --ignore-not-found=true || true
    kubectl delete ingressclass nginx --ignore-not-found=true || true
    
    echo "✓ Cleanup completed"
}

# Function to create Docker Hub secret
create_dockerhub_secret() {
    echo "Creating Docker Hub secret..."
    
    # Check if secret already exists
    if kubectl get secret dockerhub-secret -n $NAMESPACE &> /dev/null; then
        echo "  - Docker Hub secret already exists"
        return 0
    fi
    
    # Create secret (you may need to update these credentials)
    kubectl create secret docker-registry dockerhub-secret \
        --docker-server=https://index.docker.io/v1/ \
        --docker-username=khsaleh889 \
        --docker-password=your_password_here \
        --docker-email=your_email@example.com \
        -n $NAMESPACE || {
        echo "Warning: Failed to create Docker Hub secret. You may need to create it manually."
        echo "Run: kubectl create secret docker-registry dockerhub-secret --docker-server=https://index.docker.io/v1/ --docker-username=YOUR_USERNAME --docker-password=YOUR_PASSWORD --docker-email=YOUR_EMAIL -n $NAMESPACE"
    }
}

# Function to deploy Elastic Stack
deploy_elastic_stack() {
    echo "Deploying Elastic Stack..."
    
    # Deploy Elastic Stack using YAML
    kubectl apply -f elastic-stack.yml -n $NAMESPACE || {
        echo "Warning: Elastic Stack deployment failed"
        return 1
    }
    
    # Wait for Elasticsearch to be ready
    echo "  - Waiting for Elasticsearch to be ready..."
    kubectl wait --for=condition=available --timeout=600s deployment/elasticsearch -n $NAMESPACE || {
        echo "Warning: Elasticsearch deployment timed out"
    }
    
    # Wait for Kibana to be ready
    echo "  - Waiting for Kibana to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/kibana -n $NAMESPACE || {
        echo "Warning: Kibana deployment timed out"
    }
    
    echo "✓ Elastic Stack deployment completed"
}

# Function to deploy Ingress Controller
deploy_ingress_controller() {
    echo "Deploying Ingress Controller..."
    
    # Deploy NGINX Ingress Controller using YAML
    kubectl apply -f ingress-controller.yml -n $NAMESPACE || {
        echo "Warning: Ingress Controller deployment failed"
        return 1
    }
    
    # Wait for ingress controller to be ready
    echo "  - Waiting for Ingress Controller to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/ingress-nginx-controller -n $NAMESPACE || {
        echo "Warning: Ingress Controller deployment timed out"
    }
    
    echo "✓ Ingress Controller deployment completed"
}

# Function to create environment-specific ingress
create_ingress() {
    echo "Creating Ingress configuration for $ENV environment..."
    
    local ingress_file="application_deployment/$ENV/ingress.yml"
    
    # Create ingress directory
    mkdir -p "application_deployment/$ENV"
    
    # Generate ingress configuration
    cat > "$ingress_file" << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $ENV-ingress
  namespace: $NAMESPACE
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
    k8s.io/ingress-nginx: nginx
    kubernetes.io/ingress.class: nginx
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: $ENV-kube.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: api-gateway
              port:
                number: 80
          path: /
          pathType: Prefix
    - host: $ENV-kube-api.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: api-server
              port:
                number: 80
          path: /
          pathType: Prefix
    - host: $ENV-kube-app.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: angular-dev
              port:
                number: 4000
          path: /
          pathType: Prefix
    - host: $ENV-config.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: config-server
              port:
                number: 80
          path: /
          pathType: Prefix
    - host: $ENV-business-admin.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: fazeal-business-management
              port:
                number: 80
          path: /
          pathType: Prefix
    - host: $ENV-business.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: angular-business
              port:
                number: 8082
          path: /
          pathType: Prefix
    - host: $ENV-kube-cron.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: cron-jobs
              port:
                number: 80
          path: /
          pathType: Prefix
    - host: $ENV-kube-chat.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: chat-app
              port:
                number: 3000
          path: /
          pathType: Prefix
    - host: $ENV-kube-translation.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: translation-service
              port:
                number: 3001
          path: /
          pathType: Prefix
    - host: $ENV-kube-ads.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: ads-service
              port:
                number: 80
          path: /
          pathType: Prefix
    - host: $ENV-ads.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: angular-ads
              port:
                number: 8082
          path: /
          pathType: Prefix
    - host: $ENV-kube-business-chat.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: business-chat
              port:
                number: 3002
          path: /
          pathType: Prefix
    - host: $ENV-kube-post.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: posts-service
              port:
                number: 80
          path: /
          pathType: Prefix
    - host: $ENV-kube-customer.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: customer-service
              port:
                number: 80
          path: /
          pathType: Prefix
    - host: $ENV-customer.fazeal.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: angular-customer
                port:
                  number: 80
    - host: $ENV-customer-ssr.fazeal.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: angular-customer-ssr
                port:
                  number: 4000
    - host: $ENV-promotion.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: promotion-service
              port:
                number: 80
          path: /
          pathType: Prefix
    - host: $ENV-kube-logistics.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: fazeal-logistics
              port:
                number: 80
          path: /
          pathType: Prefix
    - host: $ENV-elastic.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: elasticsearch
              port:
                number: 9200
          path: /
          pathType: Prefix
    - host: $ENV-kibana.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: kibana
              port:
                number: 5601
          path: /
          pathType: Prefix
EOF
    
    echo "✓ Ingress configuration created: $ingress_file"
}

# Function to deploy all services
deploy_services() {
    echo "Deploying all services..."
    
    # List of all services
    local services=(
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
    
    local success_count=0
    local failed_services=()
    
    for service in "${services[@]}"; do
        local service_dir="application_deployment/$ENV/$service"
        
        echo "  - Deploying $service..."
        
        # Check if service directory exists
        if [ ! -d "$service_dir" ]; then
            echo "    Warning: Directory for $service does not exist, skipping..."
            failed_services+=("$service")
            continue
        fi
        
        # Deploy ConfigMap
        if [ -f "$service_dir/configmap.yml" ]; then
            kubectl apply -f "$service_dir/configmap.yml" -n $NAMESPACE
        fi
        
        # Deploy Secret
        if [ -f "$service_dir/secret.yml" ]; then
            kubectl apply -f "$service_dir/secret.yml" -n $NAMESPACE
        fi
        
        # Deploy Service
        if [ -f "$service_dir/service.yml" ]; then
            kubectl apply -f "$service_dir/service.yml" -n $NAMESPACE
        fi
        
        # Deploy Deployment
        if [ -f "$service_dir/deployment.yml" ]; then
            kubectl apply -f "$service_dir/deployment.yml" -n $NAMESPACE
        fi
        
        ((success_count++))
        echo "    ✓ Completed $service"
    done
    
    echo "✓ Services deployment completed: $success_count/${#services[@]} successful"
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        echo "Failed services: ${failed_services[*]}"
    fi
}

# Function to apply ingress
apply_ingress() {
    echo "Applying Ingress configuration..."
    kubectl apply -f "application_deployment/$ENV/ingress.yml" -n $NAMESPACE
    echo "✓ Ingress applied"
}

# Function to show deployment status
show_status() {
    echo "=========================================="
    echo "Deployment Status"
    echo "=========================================="
    
    echo "Pods:"
    kubectl get pods -n $NAMESPACE
    
    echo ""
    echo "Services:"
    kubectl get services -n $NAMESPACE
    
    echo ""
    echo "Ingress:"
    kubectl get ingress -n $NAMESPACE
    
    echo ""
    echo "Elastic Stack:"
    kubectl get pods -n $NAMESPACE | grep -E "(elasticsearch|kibana)" || echo "No Elastic Stack pods found"
    echo ""
    echo "Elasticsearch Status:"
    kubectl get pods -n $NAMESPACE -l app=elasticsearch
    echo ""
    echo "Kibana Status:"
    kubectl get pods -n $NAMESPACE -l app=kibana
    
    echo ""
    echo "Ingress Controller:"
    kubectl get pods -n $NAMESPACE | grep ingress-nginx-controller || echo "No Ingress Controller pods found"
}

# Main execution
main() {
    echo "Starting full deployment process..."
    
    # Check prerequisites
    check_kubectl
    
    # Clean up old deployments
    cleanup_old_deployments
    
    # Create Docker Hub secret
    create_dockerhub_secret
    
    # Deploy Elastic Stack
    deploy_elastic_stack
    
    # Deploy Ingress Controller
    deploy_ingress_controller
    
    # Create ingress configuration
    create_ingress
    
    # Deploy all services
    deploy_services
    
    # Apply ingress
    apply_ingress
    
    # Show status
    show_status
    
    echo "=========================================="
    echo "Full deployment completed!"
    echo "=========================================="
    echo "Monitor deployment with:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl get services -n $NAMESPACE"
    echo "  kubectl get ingress -n $NAMESPACE"
    echo ""
    echo "Access services through:"
    echo "  - API Gateway: $ENV-kube.fazeal.com"
    echo "  - API Server: $ENV-kube-api.fazeal.com"
    echo "  - Kibana: $ENV-kibana.fazeal.com"
    echo "  - Elasticsearch: $ENV-elastic.fazeal.com"
}

# Run main function
main "$@" 