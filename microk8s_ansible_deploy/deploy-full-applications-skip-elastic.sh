#!/bin/bash

# Full Application Deployment Script (Skip Elastic Stack)
# This script deploys all applications but skips Elastic Stack since it's already deployed

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-latest}
NAMESPACE=${3:-default}
JENKINS_TRIGGER=${4:-false}
JENKINS_URL=${5:-""}
JENKINS_USER=${6:-""}
JENKINS_PASSWORD=${7:-""}
JENKINS_TOKEN=${8:-""}

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}Full Application Deployment Script${NC}"
echo -e "${BLUE}==========================================${NC}"
echo "Environment: $ENVIRONMENT"
echo "Image Tag: $IMAGE_TAG"
echo "Namespace: $NAMESPACE"
echo "Jenkins Trigger: $JENKINS_TRIGGER"
echo "Jenkins URL: $JENKINS_URL"
echo -e "${BLUE}==========================================${NC}"

echo "Starting full application deployment..."
echo ""

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error: kubectl is not installed or not in PATH${NC}"
        exit 1
    fi
    
    # Test kubectl connection
    if ! kubectl cluster-info &> /dev/null; then
        echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ Connected to cluster: $(kubectl config current-context)${NC}"
}

# Function to create Docker Hub secret
create_docker_secret() {
    echo "Creating Docker Hub secret..."
    
    # Check if secret already exists
    if kubectl get secret dockerhub-secret -n $NAMESPACE &> /dev/null; then
        echo "  - Docker Hub secret already exists"
        return 0
    fi
    
    # Create secret (you may need to adjust credentials)
    kubectl create secret docker-registry dockerhub-secret \
        --docker-server=https://index.docker.io/v1/ \
        --docker-username=your-username \
        --docker-password=your-password \
        --docker-email=your-email@example.com \
        -n $NAMESPACE
    
    echo -e "${GREEN}✓ Docker Hub secret created${NC}"
}

# Function to deploy infrastructure components
deploy_infrastructure() {
    echo "Deploying infrastructure components..."
    
    # Trigger Jenkins infrastructure build if enabled
    if [ "$JENKINS_TRIGGER" = "true" ] && [ -n "$JENKINS_URL" ]; then
        echo "  - Triggering Jenkins infrastructure build..."
        if [ -f "./jenkins-trigger.sh" ]; then
            ./jenkins-trigger.sh infrastructure "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN" "$ENVIRONMENT" "$IMAGE_TAG"
        else
            echo "  - Jenkins trigger script not found, skipping"
        fi
    fi
    
    # Skip Elastic Stack deployment since it's already working
    echo "  - Skipping Elastic Stack deployment (already deployed in elasticsearch namespace)"
    
    # Deploy Ingress Controller
    echo "  - Deploying Ingress Controller..."
    if [ -d "./ansible/ingress" ]; then
        kubectl apply -f ./ansible/ingress/
        echo -e "${GREEN}✓ Ingress Controller deployed${NC}"
    else
        echo "  - Ingress templates not found, skipping"
    fi
    
    # Wait for infrastructure to be ready
    echo "  - Waiting for infrastructure to be ready..."
    sleep 30
    
    echo -e "${GREEN}✓ Infrastructure deployment completed${NC}"
}

# Function to deploy business services
deploy_business_services() {
    echo "Deploying business services..."
    
    # List of services to deploy
    services=(
        "config-server"
        "api-gateway"
        "api-server"
        "album-service"
        "ads-service"
        "angular-ads"
        "angular-business"
        "angular-customer"
        "angular-customer-ssr"
        "angular-dev"
        "angular-employees"
        "business-chat"
        "catalog-service"
        "chat-app"
        "cron-jobs"
        "customer-service"
        "employees-service"
        "events-service"
        "fazeal-business"
        "fazeal-business-management"
        "fazeal-logistics"
        "inventory-service"
        "loyalty-service"
        "notification-service"
        "order-service"
        "payment-gateway"
        "payment-service"
        "posts-service"
        "promotion-service"
        "search-service"
        "shopping-service"
        "site-management-service"
        "translation-service"
        "watermark-detection"
        "dataload-service"
    )
    
    # Deploy PV/PVC first
    echo "  - Deploying Persistent Volumes and Claims..."
    for service in "${services[@]}"; do
        if [ -f "./application_deployment/$ENVIRONMENT/$service/pv-pvc.yml" ]; then
            echo "    Deploying PV/PVC for $service..."
            kubectl apply -f "./application_deployment/$ENVIRONMENT/$service/pv-pvc.yml" -n $NAMESPACE
        fi
    done
    
    # Deploy secrets
    echo "  - Deploying secrets..."
    for service in "${services[@]}"; do
        if [ -f "./application_deployment/$ENVIRONMENT/$service/secret.yml" ]; then
            echo "    Deploying secret for $service..."
            kubectl apply -f "./application_deployment/$ENVIRONMENT/$service/secret.yml" -n $NAMESPACE
        fi
    done
    
    # Deploy configmaps
    echo "  - Deploying configmaps..."
    for service in "${services[@]}"; do
        if [ -f "./application_deployment/$ENVIRONMENT/$service/configmap.yml" ]; then
            echo "    Deploying configmap for $service..."
            kubectl apply -f "./application_deployment/$ENVIRONMENT/$service/configmap.yml" -n $NAMESPACE
        fi
    done
    
    # Deploy services
    echo "  - Deploying services..."
    for service in "${services[@]}"; do
        if [ -f "./application_deployment/$ENVIRONMENT/$service/service.yml" ]; then
            echo "    Deploying service for $service..."
            kubectl apply -f "./application_deployment/$ENVIRONMENT/$service/service.yml" -n $NAMESPACE
        fi
    done
    
    # Deploy deployments
    echo "  - Deploying deployments..."
    for service in "${services[@]}"; do
        if [ -f "./application_deployment/$ENVIRONMENT/$service/deployment.yml" ]; then
            echo "    Deploying deployment for $service..."
            kubectl apply -f "./application_deployment/$ENVIRONMENT/$service/deployment.yml" -n $NAMESPACE
        fi
    done
    
    # Deploy ingress
    echo "  - Deploying ingress..."
    for service in "${services[@]}"; do
        if [ -f "./application_deployment/$ENVIRONMENT/$service/ingress.yml" ]; then
            echo "    Deploying ingress for $service..."
            kubectl apply -f "./application_deployment/$ENVIRONMENT/$service/ingress.yml" -n $NAMESPACE
        fi
    done
    
    echo -e "${GREEN}✓ Business services deployment completed${NC}"
}

# Function to deploy HPA and PDB
deploy_hpa_pdb() {
    echo "Deploying HPA and PDB configurations..."
    
    if [ -f "./deploy-hpa-pdb-$ENVIRONMENT.sh" ]; then
        ./deploy-hpa-pdb-$ENVIRONMENT.sh $ENVIRONMENT $NAMESPACE
        echo -e "${GREEN}✓ HPA and PDB deployment completed${NC}"
    else
        echo "  - HPA/PDB deployment script not found, skipping"
    fi
}

# Function to trigger Jenkins jobs
trigger_jenkins_jobs() {
    if [ "$JENKINS_TRIGGER" = "true" ] && [ -n "$JENKINS_URL" ]; then
        echo "Triggering Jenkins jobs..."
        
        if [ -f "./jenkins-trigger.sh" ]; then
            # Trigger applications build
            echo "  - Triggering applications build..."
            ./jenkins-trigger.sh applications "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN" "$ENVIRONMENT" "$IMAGE_TAG"
            
            # Trigger frontend build
            echo "  - Triggering frontend build..."
            ./jenkins-trigger.sh frontend "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN" "$ENVIRONMENT" "$IMAGE_TAG"
            
            # Trigger deployment
            echo "  - Triggering deployment..."
            ./jenkins-trigger.sh deployment "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN" "$ENVIRONMENT" "$IMAGE_TAG"
        else
            echo "  - Jenkins trigger script not found, skipping"
        fi
    fi
}

# Function to wait for services to be ready
wait_for_services() {
    echo "Waiting for services to be ready..."
    
    # Wait for all deployments to be ready
    kubectl wait --for=condition=available --timeout=300s deployment --all -n $NAMESPACE
    
    echo -e "${GREEN}✓ All services are ready${NC}"
}

# Function to verify deployment
verify_deployment() {
    echo "Verifying deployment..."
    
    echo "  - Checking pods status..."
    kubectl get pods -n $NAMESPACE
    
    echo "  - Checking services status..."
    kubectl get services -n $NAMESPACE
    
    echo "  - Checking deployments status..."
    kubectl get deployments -n $NAMESPACE
    
    echo -e "${GREEN}✓ Deployment verification completed${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting deployment process...${NC}"
    echo ""
    
    # Check kubectl
    check_kubectl
    
    # Create Docker secret
    create_docker_secret
    
    # Deploy infrastructure
    deploy_infrastructure
    
    # Deploy business services
    deploy_business_services
    
    # Deploy HPA and PDB
    deploy_hpa_pdb
    
    # Trigger Jenkins jobs
    trigger_jenkins_jobs
    
    # Wait for services
    wait_for_services
    
    # Verify deployment
    verify_deployment
    
    echo ""
    echo -e "${GREEN}🎉 Full application deployment completed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Check all services are running: kubectl get pods -n $NAMESPACE"
    echo "2. Access applications through ingress or port-forward"
    echo "3. Monitor logs for any issues: kubectl logs -f <pod-name> -n $NAMESPACE"
    echo "4. Check Jenkins jobs status if triggered"
    echo ""
}

# Run main function
main 