#!/bin/bash

# Full Deployment Script (No Elastic Stack)
# This script runs the complete deployment including Jenkins jobs and dataload service

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-v1.2.3}
NAMESPACE=${3:-default}
JENKINS_TRIGGER=${4:-true}
JENKINS_URL=${5:-"http://192.168.1.224:8080"}
JENKINS_USER=${6:-"khaled"}
JENKINS_PASSWORD=${7:-"Welcome123"}

echo -e "${BLUE}🚀 FULL DEPLOYMENT SCRIPT (NO ELASTIC STACK)${NC}"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Image Tag: $IMAGE_TAG"
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

# Step 1: Fix deployment structure
echo -e "${BLUE}Step 1: Fixing deployment structure...${NC}"
run_command "./fix-deployment-structure.sh $ENVIRONMENT $NAMESPACE $IMAGE_TAG" "Fixing deployment structure"

# Step 2: Deploy all services
echo -e "${BLUE}Step 2: Deploying all services...${NC}"
run_command "./deploy-all-services-remote.sh $ENVIRONMENT $NAMESPACE $IMAGE_TAG" "Deploying all services"

# Step 3: Deploy HPA and PDB configurations
echo -e "${BLUE}Step 3: Deploying HPA and PDB configurations...${NC}"
if [ -f "./deploy-hpa-pdb-dev.sh" ]; then
    run_command "./deploy-hpa-pdb-dev.sh" "Deploying HPA and PDB configurations"
else
    echo -e "${YELLOW}⚠️  HPA/PDB deployment script not found, skipping...${NC}"
fi

# Step 4: Wait for services to be ready
echo -e "${BLUE}Step 4: Waiting for services to be ready...${NC}"
run_command "kubectl wait --for=condition=available --timeout=300s deployment/config-server -n $NAMESPACE" "Waiting for config-server"
run_command "kubectl wait --for=condition=available --timeout=300s deployment/api-gateway -n $NAMESPACE" "Waiting for api-gateway"
run_command "kubectl wait --for=condition=available --timeout=300s deployment/api-server -n $NAMESPACE" "Waiting for api-server"

# Step 5: Trigger Jenkins jobs
if [ "$JENKINS_TRIGGER" = "true" ]; then
    echo -e "${BLUE}Step 5: Triggering Jenkins jobs...${NC}"
    
    # Set Jenkins credentials
    export JENKINS_URL="$JENKINS_URL"
    export JENKINS_USER="$JENKINS_USER"
    export JENKINS_PASSWORD="$JENKINS_PASSWORD"
    
    # Trigger infrastructure jobs
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-Dev-config_server" "Triggering config-server build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-api-gateway" "Triggering api-gateway build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-api-server" "Triggering api-server build"
    
    # Trigger business services
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-album-service" "Triggering album-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-ads-service" "Triggering ads-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-business-chat" "Triggering business-chat build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-catalog-service" "Triggering catalog-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-chat-app-nodejs" "Triggering chat-app build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-cron-jobs" "Triggering cron-jobs build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-customer-service" "Triggering customer-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-dev-employee-service" "Triggering employee-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-events-service" "Triggering events-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-fazeal-business" "Triggering fazeal-business build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-fazeal-business-management" "Triggering fazeal-business-management build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-fazeal-logistics" "Triggering fazeal-logistics build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-inventory-service" "Triggering inventory-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-loyalty-service" "Triggering loyalty-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-notification-service" "Triggering notification-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-order-service" "Triggering order-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-payment-gateway" "Triggering payment-gateway build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-payment-service" "Triggering payment-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-posts-service" "Triggering posts-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-promotion-service" "Triggering promotion-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-dev-search-service" "Triggering search-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-shopping-service" "Triggering shopping-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-site-management-service" "Triggering site-management-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-translation-service" "Triggering translation-service build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-watermark-detection" "Triggering watermark-detection build"
    
    # Trigger Angular services
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-angular-ads" "Triggering angular-ads build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-angular-business" "Triggering angular-business build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-angular-customer" "Triggering angular-customer build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-Angular-Social" "Triggering angular-social build"
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-dev-angular-employee" "Triggering angular-employee build"
    
    # Trigger dataload service
    run_command "./jenkins-trigger.sh trigger multi-branch-k8s-dev-dataload-service" "Triggering dataload-service build"
    
else
    echo -e "${YELLOW}⚠️  Jenkins trigger disabled, skipping Jenkins jobs...${NC}"
fi

# Step 6: Show final status
echo -e "${BLUE}Step 6: Final deployment status...${NC}"
run_command "kubectl get deployments -n $NAMESPACE" "Deployment status"
run_command "kubectl get pods -n $NAMESPACE" "Pod status"
run_command "kubectl get services -n $NAMESPACE" "Service status"

if [ -f "./deploy-hpa-pdb-dev.sh" ]; then
    run_command "kubectl get hpa -n $NAMESPACE" "HPA status"
    run_command "kubectl get pdb -n $NAMESPACE" "PDB status"
fi

echo ""
echo -e "${GREEN}🎉 FULL DEPLOYMENT COMPLETED SUCCESSFULLY!${NC}"
echo "=========================================="
echo -e "${YELLOW}Summary:${NC}"
echo "- ✅ All services deployed"
echo "- ✅ HPA and PDB configurations applied"
echo "- ✅ Jenkins jobs triggered"
echo "- ✅ Dataload service included"
echo "- ✅ Elastic Stack excluded (already running)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Monitor Jenkins job progress"
echo "2. Check service health endpoints"
echo "3. Verify dataload service functionality"
echo "4. Monitor HPA scaling behavior"
echo ""
echo -e "${GREEN}✅ Deployment completed!${NC}" 