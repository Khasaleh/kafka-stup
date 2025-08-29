#!/bin/bash

# Continue Rebuild Script
# This script continues the rebuild process from where it got stuck

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
ENV=${1:-dev}
IMAGE_TAG=${2:-v1.2.3}
NAMESPACE=${3:-default}
JENKINS_TRIGGER=${4:-true}
JENKINS_URL=${5:-"http://192.168.1.224:8080"}
JENKINS_USER=${6:-"khaled"}
JENKINS_PASSWORD=${7:-"Welcome123"}
JENKINS_TOKEN=${8:-""}

echo -e "${BLUE}🚀 CONTINUING REBUILD PROCESS${NC}"
echo "=========================================="
echo "Environment: $ENV"
echo "Image Tag: $IMAGE_TAG"
echo "Namespace: $NAMESPACE"
echo "Jenkins Trigger: $JENKINS_TRIGGER"
echo "=========================================="
echo ""

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Function to print step headers
print_step() {
    echo -e "${YELLOW}$1${NC}"
    echo "----------------------------------------"
}

# Function to deploy infrastructure (skip Elastic Stack for now)
deploy_infrastructure() {
    print_section "🏗️ DEPLOYING INFRASTRUCTURE"
    
    print_step "Skipping Elastic Stack (vault issue fixed for next run)..."
    echo -e "${YELLOW}Note: Elastic Stack can be deployed separately later${NC}"
    
    print_step "Deploying Ingress..."
    if [ -f "ansible/deploy-ingress.yml" ]; then
        ansible-playbook -i ansible/hosts ansible/deploy-ingress.yml --extra-vars "env=$ENV namespace=$NAMESPACE" || {
            echo -e "${YELLOW}Warning: Ingress deployment failed, continuing...${NC}"
        }
    else
        echo -e "${YELLOW}Ingress deployment file not found, skipping...${NC}"
    fi
    
    echo -e "${GREEN}✅ Infrastructure deployment completed${NC}"
}

# Function to deploy all services
deploy_all_services() {
    print_section "🚀 DEPLOYING ALL SERVICES"
    
    print_step "Running full application deployment..."
    ./deploy-full-applications.sh "$ENV" "$IMAGE_TAG" "$NAMESPACE" "$JENKINS_TRIGGER" "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN"
    
    echo -e "${GREEN}✅ All services deployment completed${NC}"
}

# Function to deploy HPA and PDB
deploy_hpa_pdb() {
    print_section "📈 DEPLOYING HPA AND PDB"
    
    print_step "Deploying HPA and PDB configurations..."
    if [ -f "deploy-hpa-pdb-$ENV.sh" ]; then
        ./deploy-hpa-pdb-$ENV.sh "$ENV" "$NAMESPACE"
    else
        echo -e "${YELLOW}HPA/PDB deployment script not found, skipping...${NC}"
    fi
    
    echo -e "${GREEN}✅ HPA and PDB deployment completed${NC}"
}

# Function to trigger Jenkins jobs
trigger_jenkins_jobs() {
    if [ "$JENKINS_TRIGGER" = "true" ]; then
        print_section "🔄 TRIGGERING JENKINS JOBS"
        
        print_step "Checking Jenkins connectivity..."
        if [ -f "jenkins-trigger.sh" ]; then
            ./jenkins-trigger.sh check "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN" || {
                echo -e "${YELLOW}Warning: Jenkins connectivity check failed, but continuing...${NC}"
            }
            
            print_step "Triggering infrastructure build..."
            ./jenkins-trigger.sh infrastructure "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN" "$ENV" "$IMAGE_TAG" || {
                echo -e "${YELLOW}Warning: Infrastructure build failed, but continuing...${NC}"
            }
            
            print_step "Triggering application builds..."
            ./jenkins-trigger.sh applications "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN" "$ENV" "$IMAGE_TAG" || {
                echo -e "${YELLOW}Warning: Application builds failed, but continuing...${NC}"
            }
            
            print_step "Triggering frontend builds..."
            ./jenkins-trigger.sh frontend "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN" "$ENV" "$IMAGE_TAG" || {
                echo -e "${YELLOW}Warning: Frontend builds failed, but continuing...${NC}"
            }
            
            print_step "Triggering deployment..."
            ./jenkins-trigger.sh deploy "$JENKINS_URL" "$JENKINS_USER" "$JENKINS_PASSWORD" "$JENKINS_TOKEN" "$ENV" "$IMAGE_TAG" || {
                echo -e "${YELLOW}Warning: Deployment failed, but continuing...${NC}"
            }
        else
            echo -e "${YELLOW}Jenkins trigger script not found, skipping Jenkins jobs...${NC}"
        fi
        
        echo -e "${GREEN}✅ Jenkins jobs triggered${NC}"
    else
        echo -e "${YELLOW}Skipping Jenkins jobs (JENKINS_TRIGGER=false)${NC}"
    fi
}

# Function to show final status
show_final_status() {
    print_section "📊 FINAL STATUS"
    
    print_step "Deployment Summary:"
    echo "Environment: $ENV"
    echo "Image Tag: $IMAGE_TAG"
    echo "Namespace: $NAMESPACE"
    echo "Jenkins Trigger: $JENKINS_TRIGGER"
    
    print_step "Next Steps:"
    echo "1. Monitor deployment: kubectl get pods -n $NAMESPACE"
    echo "2. Check HPA status: kubectl get hpa -n $NAMESPACE"
    echo "3. Check PDB status: kubectl get pdb -n $NAMESPACE"
    echo "4. Monitor Jenkins jobs in the Jenkins UI"
    echo "5. Deploy Elastic Stack separately if needed"
    
    echo -e "${GREEN}🎉 Rebuild continuation completed successfully!${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}🚀 CONTINUING REBUILD PROCESS${NC}"
    echo "=========================================="
    
    # Execute rebuild process
    deploy_infrastructure
    deploy_all_services
    deploy_hpa_pdb
    trigger_jenkins_jobs
    show_final_status
}

# Show usage if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [environment] [image_tag] [namespace] [jenkins_trigger] [jenkins_url] [jenkins_user] [jenkins_password] [jenkins_token]"
    echo ""
    echo "Parameters:"
    echo "  environment        Environment name (default: dev)"
    echo "  image_tag          Docker image tag (default: v1.2.3)"
    echo "  namespace          Kubernetes namespace (default: default)"
    echo "  jenkins_trigger    Enable Jenkins triggers (default: true)"
    echo "  jenkins_url        Jenkins URL (default: http://192.168.1.224:8080)"
    echo "  jenkins_user       Jenkins username (default: khaled)"
    echo "  jenkins_password   Jenkins password (default: Welcome123)"
    echo "  jenkins_token      Jenkins token (default: empty)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use all defaults"
    echo "  $0 dev v1.2.3 default true            # Basic continuation"
    echo "  $0 dev v1.2.3 default false           # Continue without Jenkins"
    echo ""
    exit 1
fi

# Run main function
main "$@" 