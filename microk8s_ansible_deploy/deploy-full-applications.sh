#!/bin/bash

# Full Application Deployment Script
# This script deploys all microservices with proper startup order and dependencies

set -e  # Exit on any error

# Configuration
ENV=${1:-dev}
IMAGE_TAG=${2:-latest}
NAMESPACE=${3:-default}
JENKINS_TRIGGER=${4:-false}
JENKINS_URL=${5:-"http://192.168.1.224:8080"}
JENKINS_USER=${6:-"khaled"}
JENKINS_PASSWORD=${7:-"Welcome123"}
JENKINS_TOKEN=${8:-""}

echo "=========================================="
echo "Full Application Deployment Script"
echo "=========================================="
echo "Environment: $ENV"
echo "Image Tag: $IMAGE_TAG"
echo "Namespace: $NAMESPACE"
echo "Jenkins Trigger: $JENKINS_TRIGGER"
if [ "$JENKINS_TRIGGER" = "true" ]; then
    echo "Jenkins URL: $JENKINS_URL"
fi
echo "=========================================="

# Function to check prerequisites
check_prerequisites() {
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

# Function to create Docker Hub secret
create_dockerhub_secret() {
    echo "Creating Docker Hub secret..."
    
    if kubectl get secret dockerhub-secret -n $NAMESPACE &> /dev/null; then
        echo "  - Docker Hub secret already exists"
        return 0
    fi
    
    kubectl create secret docker-registry dockerhub-secret \
        --docker-server=https://index.docker.io/v1/ \
        --docker-username=khsaleh889 \
        --docker-password=your_password_here \
        --docker-email=your_email@example.com \
        -n $NAMESPACE || {
        echo "Warning: Failed to create Docker Hub secret. You may need to create it manually."
    }
}

# Function to deploy infrastructure components
deploy_infrastructure() {
    echo "Deploying infrastructure components..."
    
    # Trigger Jenkins infrastructure build if enabled
    if [ "$JENKINS_TRIGGER" = "true" ]; then
        echo "  - Triggering Jenkins infrastructure build..."
        ./jenkins-trigger.sh infrastructure "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN" "$ENV" "$IMAGE_TAG" || {
            echo "  ⚠ Jenkins infrastructure build failed, continuing with local deployment"
        }
    fi
    
    # Deploy Elastic Stack
    echo "  - Deploying Elastic Stack..."
    kubectl apply -f elastic-stack.yml -n $NAMESPACE
    
    # Deploy Ingress Controller
    echo "  - Deploying Ingress Controller..."
    kubectl apply -f ingress-controller.yml -n $NAMESPACE
    
    # Wait for infrastructure to be ready
    echo "  - Waiting for infrastructure to be ready..."
    kubectl wait --for=condition=available --timeout=600s deployment/elasticsearch -n $NAMESPACE || true
    kubectl wait --for=condition=available --timeout=300s deployment/kibana -n $NAMESPACE || true
    kubectl wait --for=condition=available --timeout=300s deployment/ingress-nginx-controller -n $NAMESPACE || true
    
    echo "✓ Infrastructure deployment completed"
}

# Function to deploy core services first (dependencies)
deploy_core_services() {
    echo "Deploying core services (dependencies)..."
    
    # Trigger Jenkins application builds if enabled
    if [ "$JENKINS_TRIGGER" = "true" ]; then
        echo "  - Triggering Jenkins application builds..."
        ./jenkins-trigger.sh applications "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN" "$ENV" "$IMAGE_TAG" || {
            echo "  ⚠ Jenkins application builds failed, continuing with local deployment"
        }
    fi
    
    local core_services=(
        "config-server"
        "api-server"
        "api-gateway"
    )
    
    for service in "${core_services[@]}"; do
        echo "  - Deploying $service..."
        deploy_service "$service"
        
        # Wait for service to be ready
        echo "    Waiting for $service to be ready..."
        kubectl wait --for=condition=available --timeout=300s deployment/$service -n $NAMESPACE || {
            echo "    Warning: $service deployment timed out"
        }
    done
    
    echo "✓ Core services deployment completed"
}

# Function to deploy business services
deploy_business_services() {
    echo "Deploying business services..."
    
    local business_services=(
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
        "cron-jobs"
        "chat-app"
        "business-chat"
        "album-service"
        "ads-service"
        "promotion-service"
        "catalog-service"
        "customer-service"
        "employees-service"
        "payment-service"
        "translation-service"
        "watermark-detection"
        "dataload-service"
    )
    
    for service in "${business_services[@]}"; do
        echo "  - Deploying $service..."
        deploy_service "$service"
    done
    
    echo "✓ Business services deployment completed"
}

# Function to deploy frontend applications
deploy_frontend_apps() {
    echo "Deploying frontend applications..."
    
    # Trigger Jenkins frontend builds if enabled
    if [ "$JENKINS_TRIGGER" = "true" ]; then
        echo "  - Triggering Jenkins frontend builds..."
        ./jenkins-trigger.sh frontend "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN" "$ENV" "$IMAGE_TAG" || {
            echo "  ⚠ Jenkins frontend builds failed, continuing with local deployment"
        }
    fi
    
    local frontend_apps=(
        "angular-dev"
        "angular-customer"
        "angular-business"
        "angular-ads"
        "angular-employee"
        "angular-customer-ssr"
    )
    
    for app in "${frontend_apps[@]}"; do
        echo "  - Deploying $app..."
        deploy_service "$app"
    done
    
    echo "✓ Frontend applications deployment completed"
}

# Function to deploy a single service
deploy_service() {
    local service="$1"
    local service_dir="application_deployment/$ENV/$service"
    
    if [ ! -d "$service_dir" ]; then
        echo "    Warning: Directory for $service does not exist, skipping..."
        return 1
    fi
    
    # Update image tag in deployment if it exists
    if [ -f "$service_dir/deployment.yml" ]; then
        # Create a temporary deployment file with updated image tag
        local temp_deployment="/tmp/${service}-deployment.yml"
        sed "s/\$IMAGE/$IMAGE_TAG/g" "$service_dir/deployment.yml" > "$temp_deployment"
        
        # Deploy ConfigMap
        if [ -f "$service_dir/configmap.yml" ]; then
            kubectl apply -f "$service_dir/configmap.yml" -n $NAMESPACE
        fi
        
        # Deploy PersistentVolume and PersistentVolumeClaim first (if they exist)
        if [ -f "$service_dir/pv-pvc.yml" ]; then
            kubectl apply -f "$service_dir/pv-pvc.yml" -n $NAMESPACE
        fi
        
        # Deploy Secret
        if [ -f "$service_dir/secret.yml" ]; then
            kubectl apply -f "$service_dir/secret.yml" -n $NAMESPACE
        fi
        
        # Deploy Service
        if [ -f "$service_dir/service.yml" ]; then
            kubectl apply -f "$service_dir/service.yml" -n $NAMESPACE
        fi
        
        # Deploy Deployment with updated image tag
        kubectl apply -f "$temp_deployment" -n $NAMESPACE
        
        # Clean up temporary file
        rm -f "$temp_deployment"
        
        echo "    ✓ Deployed $service"
    else
        echo "    Warning: Deployment file for $service not found"
    fi
}

# Function to create ingress configuration
create_ingress() {
    echo "Creating ingress configuration..."
    
    local ingress_file="application_deployment/$ENV/ingress.yml"
    mkdir -p "application_deployment/$ENV"
    
    # Generate ingress configuration (same as before)
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
    - host: $ENV-customer.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: angular-customer
              port:
                number: 80
          path: /
          pathType: Prefix
    - host: $ENV-customer-ssr.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: angular-customer-ssr
              port:
                number: 4000
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
    - host: $ENV-kube-order.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: order-service
              port:
                number: 80
          path: /
          pathType: Prefix
    - host: $ENV-kube-payment.fazeal.com
      http:
        paths:
        - backend:
            service:
              name: payment-service
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
    
    kubectl apply -f "$ingress_file" -n $NAMESPACE
    echo "✓ Ingress configuration applied"
}

# Function to wait for all services to be ready
wait_for_services() {
    echo "Waiting for all services to be ready..."
    
    local all_services=(
        "config-server"
        "api-server"
        "api-gateway"
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
        "cron-jobs"
        "chat-app"
        "business-chat"
        "album-service"
        "ads-service"
        "promotion-service"
        "catalog-service"
        "customer-service"
        "employees-service"
        "payment-service"
        "translation-service"
        "watermark-detection"
        "angular-dev"
        "angular-customer"
        "angular-business"
        "angular-ads"
        "angular-employee"
        "angular-customer-ssr"
    )
    
    local ready_count=0
    local total_services=${#all_services[@]}
    
    for service in "${all_services[@]}"; do
        if kubectl get deployment $service -n $NAMESPACE &> /dev/null; then
            echo "  - Waiting for $service..."
            if kubectl wait --for=condition=available --timeout=300s deployment/$service -n $NAMESPACE; then
                ((ready_count++))
                echo "    ✓ $service is ready"
            else
                echo "    ⚠ $service is not ready (timeout)"
            fi
        else
            echo "  - Skipping $service (deployment not found)"
        fi
    done
    
    echo "✓ Services ready: $ready_count/$total_services"
}

# Function to show deployment status
show_status() {
    echo "=========================================="
    echo "Deployment Status"
    echo "=========================================="
    
    echo "Pods Status:"
    kubectl get pods -n $NAMESPACE
    
    echo ""
    echo "Services Status:"
    kubectl get services -n $NAMESPACE
    
    echo ""
    echo "Deployments Status:"
    kubectl get deployments -n $NAMESPACE
    
    echo ""
    echo "Ingress Status:"
    kubectl get ingress -n $NAMESPACE
    
    echo ""
    echo "Infrastructure Status:"
    kubectl get pods -n $NAMESPACE | grep -E "(elasticsearch|kibana|ingress-nginx)" || echo "No infrastructure pods found"
}

# Main execution
main() {
    echo "Starting full application deployment..."
    
    # Check prerequisites
    check_prerequisites
    
    # Create Docker Hub secret
    create_dockerhub_secret
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Deploy core services first
    deploy_core_services
    
    # Deploy business services
    deploy_business_services
    
    # Deploy frontend applications
    deploy_frontend_apps
    
    # Create ingress configuration
    create_ingress
    
    # Trigger Jenkins deployment if enabled
    if [ "$JENKINS_TRIGGER" = "true" ]; then
        echo "Triggering Jenkins deployment..."
        ./jenkins-trigger.sh deploy "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN" "$ENV" "$IMAGE_TAG" || {
            echo "⚠ Jenkins deployment failed, continuing with local deployment"
        }
    fi
    
    # Wait for all services to be ready
    wait_for_services
    
    # Show status
    show_status
    
    echo "=========================================="
    echo "Full application deployment completed!"
    echo "=========================================="
    echo "Monitor deployment with:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl get services -n $NAMESPACE"
    echo "  kubectl get deployments -n $NAMESPACE"
    echo ""
    echo "Access applications through:"
    echo "  - API Gateway: $ENV-kube.fazeal.com"
    echo "  - API Server: $ENV-kube-api.fazeal.com"
    echo "  - Business Admin: $ENV-business-admin.fazeal.com"
    echo "  - Customer Portal: $ENV-customer.fazeal.com"
    echo "  - Kibana: $ENV-kibana.fazeal.com"
    echo "  - Elasticsearch: $ENV-elastic.fazeal.com"
    echo ""
    echo "Check service logs:"
    echo "  kubectl logs -f deployment/<service-name> -n $NAMESPACE"
}

# Run main function
main "$@" 