#!/bin/bash

# Complete Environment Rebuild Script
# This script clears everything and applies existing YAML files from application_deployment/dev

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-dev}
NAMESPACE=${2:-default}
JENKINS_TRIGGER=${3:-true}
JENKINS_URL=${4:-"http://192.168.1.224:8080"}
JENKINS_USER=${5:-"khaled"}
JENKINS_PASSWORD=${6:-"Welcome123"}

echo -e "${BLUE}🚀 COMPLETE ENVIRONMENT REBUILD SCRIPT${NC}"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo "Jenkins Trigger: $JENKINS_TRIGGER"
echo "Jenkins URL: $JENKINS_URL"
echo "=========================================="

# Function to run command with status
run_command() {
    local command="$1"
    local description="$2"
    
    echo -e "${YELLOW}$description${NC}"
    echo "----------------------------------------"
    
    if eval "$command"; then
        echo -e "${GREEN}✅ $description completed${NC}"
    else
        echo -e "${RED}❌ $description failed${NC}"
        return 1
    fi
    echo ""
}

# Function to wait for cleanup
wait_for_cleanup() {
    echo -e "${YELLOW}Waiting for cleanup to complete...${NC}"
    sleep 10
    echo -e "${GREEN}✅ Cleanup wait completed${NC}"
}

# Function to trigger Jenkins job and wait for completion
trigger_jenkins_job_and_wait() {
    local job_name="$1"
    local description="$2"
    
    echo -e "${YELLOW}Triggering: $description${NC}"
    echo "----------------------------------------"
    
    # Trigger the job
    if ./jenkins-trigger.sh trigger "$job_name"; then
        echo -e "${GREEN}✅ Job triggered successfully${NC}"
        
        # Wait for job completion
        echo -e "${YELLOW}Waiting for job to complete...${NC}"
        if ./jenkins-trigger.sh wait "$job_name"; then
            echo -e "${GREEN}✅ $description completed successfully${NC}"
        else
            echo -e "${RED}❌ $description failed or timed out${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Failed to trigger $description${NC}"
        return 1
    fi
    echo ""
}

# Step 1: Clear Everything
echo -e "${BLUE}Step 1: Clearing Everything${NC}"
echo "=========================================="

# Delete all deployments
run_command "kubectl delete deployment --all -n $NAMESPACE --ignore-not-found=true" "Deleting all deployments"

# Delete all services
run_command "kubectl delete service --all -n $NAMESPACE --ignore-not-found=true" "Deleting all services"

# Delete all configmaps
run_command "kubectl delete configmap --all -n $NAMESPACE --ignore-not-found=true" "Deleting all configmaps"

# Delete all secrets
run_command "kubectl delete secret --all -n $NAMESPACE --ignore-not-found=true" "Deleting all secrets"

# Delete all HPA
run_command "kubectl delete hpa --all -n $NAMESPACE --ignore-not-found=true" "Deleting all HPA"

# Delete all PDB
run_command "kubectl delete pdb --all -n $NAMESPACE --ignore-not-found=true" "Deleting all PDB"

# Delete ingress
run_command "kubectl delete ingress dev-ingress -n $NAMESPACE --ignore-not-found=true" "Deleting ingress"

# Wait for cleanup
wait_for_cleanup

# Step 2: Create Docker Hub Secret
echo -e "${BLUE}Step 2: Creating Docker Hub Secret${NC}"
echo "=========================================="
run_command "kubectl create secret docker-registry dockerhub-secret --docker-server=https://index.docker.io/v1/ --docker-username=khsaleh889 --docker-password=your_password_here --docker-email=your_email@example.com --dry-run=client -o yaml | kubectl apply -f -" "Creating Docker Hub secret"

# Step 3: Apply All YAML Files from application_deployment/dev
echo -e "${BLUE}Step 3: Applying All YAML Files from application_deployment/dev${NC}"
echo "=========================================="

# Get list of all service directories
SERVICE_DIRS=$(find "./application_deployment/$ENVIRONMENT" -maxdepth 1 -type d -name "*" | grep -v "^./application_deployment/$ENVIRONMENT$" | sort)

for service_dir in $SERVICE_DIRS; do
    service_name=$(basename "$service_dir")
    echo -e "${YELLOW}Processing service: $service_name${NC}"
    
    # Apply secrets first
    if [ -f "$service_dir/secret.yml" ]; then
        run_command "kubectl apply -f $service_dir/secret.yml" "Applying secret for $service_name"
    fi
    
    # Apply configmaps
    if [ -f "$service_dir/configmap.yml" ]; then
        run_command "kubectl apply -f $service_dir/configmap.yml" "Applying configmap for $service_name"
    fi
    
    # Apply services
    if [ -f "$service_dir/service.yml" ]; then
        run_command "kubectl apply -f $service_dir/service.yml" "Applying service for $service_name"
    fi
    
    # Apply deployments
    if [ -f "$service_dir/deployment.yml" ]; then
        run_command "kubectl apply -f $service_dir/deployment.yml" "Applying deployment for $service_name"
    fi
    
    # Apply HPA if exists
    if [ -f "$service_dir/hpa.yml" ]; then
        run_command "kubectl apply -f $service_dir/hpa.yml" "Applying HPA for $service_name"
    fi
    
    # Apply PDB if exists
    if [ -f "$service_dir/pdb.yml" ]; then
        run_command "kubectl apply -f $service_dir/pdb.yml" "Applying PDB for $service_name"
    fi
    
    # Apply PV/PVC if exists
    if [ -f "$service_dir/pv-pvc.yml" ]; then
        run_command "kubectl apply -f $service_dir/pv-pvc.yml" "Applying PV/PVC for $service_name"
    fi
    
    echo ""
done

# Step 4: Deploy Ingress-Nginx Setup and Dev Ingress
echo -e "${BLUE}Step 4: Deploying Ingress-Nginx Setup and Dev Ingress${NC}"
echo "=========================================="

# Deploy Ingress-Nginx Setup first
run_command "kubectl apply -f ingress-nginx-setup.yml" "Deploying ingress-nginx setup"

# Wait for Ingress-Nginx to be ready
run_command "kubectl wait --for=condition=available --timeout=300s deployment/ingress-nginx-controller -n default" "Waiting for ingress-nginx-controller"

# Wait for admission webhook jobs to complete
run_command "kubectl wait --for=condition=complete --timeout=120s job/ingress-nginx-admission-create -n default" "Waiting for admission-create job"
run_command "kubectl wait --for=condition=complete --timeout=120s job/ingress-nginx-admission-patch -n default" "Waiting for admission-patch job"

# Now deploy the dev ingress
run_command "kubectl apply -f dev-ingress.yml" "Deploying dev ingress"

# Step 5: Trigger Critical Jenkins Jobs First (One by One)
if [ "$JENKINS_TRIGGER" = "true" ]; then
    echo -e "${BLUE}Step 5: Triggering Critical Jenkins Jobs (One by One)${NC}"
    echo "=========================================="
    
    # Set Jenkins credentials
    export JENKINS_URL="$JENKINS_URL"
    export JENKINS_USER="$JENKINS_USER"
    export JENKINS_PASSWORD="$JENKINS_PASSWORD"
    
    # Critical Infrastructure Jobs (must be built first)
    echo -e "${YELLOW}🚨 CRITICAL INFRASTRUCTURE JOBS (Building First)${NC}"
    echo "=========================================="
    
    trigger_jenkins_job_and_wait "multi-branch-k8s-Dev-config_server" "Config Server Build"
    trigger_jenkins_job_and_wait "multi-branch-k8s-api-gateway" "API Gateway Build"
    trigger_jenkins_job_and_wait "multi-branch-k8s-api-server" "API Server Build"
    
    # Core Business Services (dependencies for other services)
    echo -e "${YELLOW}🏗️ CORE BUSINESS SERVICES (Building Next)${NC}"
    echo "=========================================="
    
    trigger_jenkins_job_and_wait "multi-branch-k8s-album-service" "Album Service Build"
    trigger_jenkins_job_and_wait "multi-branch-k8s-catalog-service" "Catalog Service Build"
    trigger_jenkins_job_and_wait "multi-branch-k8s-customer-service" "Customer Service Build"
    trigger_jenkins_job_and_wait "multi-branch-k8s-order-service" "Order Service Build"
    trigger_jenkins_job_and_wait "multi-branch-k8s-payment-service" "Payment Service Build"
    
    # Business Management Services
    echo -e "${YELLOW}💼 BUSINESS MANAGEMENT SERVICES${NC}"
    echo "=========================================="
    
    trigger_jenkins_job_and_wait "multi-branch-k8s-fazeal-business" "Fazeal Business Build"
    trigger_jenkins_job_and_wait "multi-branch-k8s-fazeal-business-management" "Fazeal Business Management Build"
    trigger_jenkins_job_and_wait "multi-branch-k8s-site-management-service" "Site Management Service Build"
    
    # Data and Utility Services
    echo -e "${YELLOW}📊 DATA AND UTILITY SERVICES${NC}"
    echo "=========================================="
    
    trigger_jenkins_job_and_wait "multi-branch-k8s-dev-dataload-service" "Dataload Service Build"
    trigger_jenkins_job_and_wait "multi-branch-k8s-dev-search-service" "Search Service Build"
    trigger_jenkins_job_and_wait "multi-branch-k8s-translation-service" "Translation Service Build"
    trigger_jenkins_job_and_wait "multi-branch-k8s-watermark-detection" "Watermark Detection Build"
    
    # Remaining Business Services (can be built in parallel)
    echo -e "${YELLOW}🔄 REMAINING BUSINESS SERVICES (Parallel Build)${NC}"
    echo "=========================================="
    
    # Trigger remaining services without waiting (they can build in parallel)
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-ads-service" "Triggering ads-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-business-chat" "Triggering business-chat build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-chat-app-nodejs" "Triggering chat-app build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-cron-jobs" "Triggering cron-jobs build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-dev-employee-service" "Triggering employee-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-events-service" "Triggering events-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-fazeal-logistics" "Triggering fazeal-logistics build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-inventory-service" "Triggering inventory-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-loyalty-service" "Triggering loyalty-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-notification-service" "Triggering notification-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-payment-gateway" "Triggering payment-gateway build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-posts-service" "Triggering posts-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-promotion-service" "Triggering promotion-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-shopping-service" "Triggering shopping-service build"
    
    # Angular Frontend Services (can be built in parallel)
    echo -e "${YELLOW}🎨 ANGULAR FRONTEND SERVICES (Parallel Build)${NC}"
    echo "=========================================="
    
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-angular-ads" "Triggering angular-ads build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-angular-business" "Triggering angular-business build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-angular-customer" "Triggering angular-customer build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-Angular-Social" "Triggering angular-social build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-dev-angular-employee" "Triggering angular-employee build"
    
else
    echo -e "${YELLOW}⚠️  Jenkins trigger disabled, skipping Jenkins jobs...${NC}"
fi

# Step 6: Wait for Critical Services (after Jenkins jobs)
echo -e "${BLUE}Step 6: Waiting for Critical Services (after Jenkins builds)${NC}"
echo "=========================================="
echo -e "${YELLOW}Note: Services will be ready after Jenkins jobs complete building and deploying${NC}"
run_command "kubectl wait --for=condition=available --timeout=600s deployment/config-server -n $NAMESPACE" "Waiting for config-server"
run_command "kubectl wait --for=condition=available --timeout=600s deployment/api-gateway -n $NAMESPACE" "Waiting for api-gateway"
run_command "kubectl wait --for=condition=available --timeout=600s deployment/api-server -n $NAMESPACE" "Waiting for api-server"

# Step 7: Show Final Status
echo -e "${BLUE}Step 7: Final Deployment Status${NC}"
echo "=========================================="
run_command "kubectl get deployments -n $NAMESPACE" "Deployment status"
run_command "kubectl get pods -n $NAMESPACE" "Pod status"
run_command "kubectl get services -n $NAMESPACE" "Service status"
run_command "kubectl get ingress -n $NAMESPACE" "Ingress status"
run_command "kubectl get hpa -n $NAMESPACE" "HPA status"
run_command "kubectl get pdb -n $NAMESPACE" "PDB status"

echo ""
echo -e "${GREEN}🎉 COMPLETE ENVIRONMENT REBUILD SUCCESSFULLY!${NC}"
echo "=========================================="
echo -e "${YELLOW}Summary:${NC}"
echo "- ✅ Everything cleared"
echo "- ✅ Docker Hub secret created"
echo "- ✅ All YAML files applied from application_deployment/$ENVIRONMENT"
echo "- ✅ Ingress deployed"
echo "- ✅ Critical Jenkins jobs triggered and completed"
echo "- ✅ Remaining jobs triggered in parallel"
echo "- ✅ Critical services ready (after Jenkins builds)"
echo "- ✅ Dataload service included"
echo ""
echo -e "${YELLOW}Access Points:${NC}"
echo "- Main API Gateway: https://dev-kube.fazeal.com"
echo "- API Server: https://dev-kube-api.fazeal.com"
echo "- Config Server: https://dev-config.fazeal.com"
echo "- Customer App: https://dev-customer.fazeal.com"
echo "- Business App: https://dev-business.fazeal.com"
echo "- Dataload Service: https://dev-dataload.fazeal.com"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Monitor remaining Jenkins job progress"
echo "2. Check service health endpoints"
echo "3. Verify dataload service functionality"
echo "4. Monitor HPA scaling behavior"
echo "5. Test ingress routing"
echo ""
echo -e "${GREEN}✅ Complete rebuild finished!${NC}" 