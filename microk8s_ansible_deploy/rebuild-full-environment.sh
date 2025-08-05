#!/bin/bash

# Full Environment Rebuild Script
# This script cleans everything, rebuilds the full environment, and triggers Jenkins jobs

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
ENV=${1:-dev}
IMAGE_TAG=${2:-latest}
NAMESPACE=${3:-default}
JENKINS_TRIGGER=${4:-true}
JENKINS_URL=${5:-"http://192.168.1.224:8080"}
JENKINS_USER=${6:-"khaled"}
JENKINS_PASSWORD=${7:-"Welcome123"}
JENKINS_TOKEN=${8:-""}

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

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo -e "${RED}Error: kubectl is not installed or not in PATH${NC}"
        exit 1
    fi
}

# Function to check if namespace exists
check_namespace() {
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        echo -e "${YELLOW}Creating namespace $NAMESPACE...${NC}"
        kubectl create namespace $NAMESPACE
    fi
}

# Function to clean up all resources
cleanup_environment() {
    print_section "🧹 CLEANING UP ENVIRONMENT"
    
    print_step "Cleaning up deployments..."
    kubectl delete deployments --all -n $NAMESPACE --ignore-not-found=true || true
    
    print_step "Cleaning up services..."
    kubectl delete services --all -n $NAMESPACE --ignore-not-found=true || true
    
    print_step "Cleaning up configmaps..."
    kubectl delete configmaps --all -n $NAMESPACE --ignore-not-found=true || true
    
    print_step "Cleaning up secrets..."
    kubectl delete secrets --all -n $NAMESPACE --ignore-not-found=true || true
    
    print_step "Cleaning up HPA..."
    kubectl delete hpa --all -n $NAMESPACE --ignore-not-found=true || true
    
    print_step "Cleaning up PDB..."
    kubectl delete pdb --all -n $NAMESPACE --ignore-not-found=true || true
    
    print_step "Cleaning up PVC..."
    kubectl delete pvc --all -n $NAMESPACE --ignore-not-found=true || true
    
    print_step "Cleaning up PV..."
    kubectl delete pv --all --ignore-not-found=true || true
    
    print_step "Cleaning up ingress..."
    kubectl delete ingress --all -n $NAMESPACE --ignore-not-found=true || true
    
    print_step "Cleaning up jobs..."
    kubectl delete jobs --all -n $NAMESPACE --ignore-not-found=true || true
    
    print_step "Cleaning up pods..."
    kubectl delete pods --all -n $NAMESPACE --ignore-not-found=true || true
    
    echo -e "${GREEN}✅ Environment cleanup completed${NC}"
}

# Function to wait for cleanup
wait_for_cleanup() {
    print_step "Waiting for cleanup to complete..."
    
    # Wait for pods to be terminated
    while kubectl get pods -n $NAMESPACE 2>/dev/null | grep -v "No resources found" | grep -v "NAME"; do
        echo "Waiting for pods to be terminated..."
        sleep 5
    done
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Function to deploy infrastructure
deploy_infrastructure() {
    print_section "🏗️ DEPLOYING INFRASTRUCTURE"
    
    print_step "Deploying Elastic Stack (YAML-based)..."
    if [ -f "ansible/deploy-elastic-stack-yaml.yml" ]; then
        ansible-playbook -i ansible/hosts ansible/deploy-elastic-stack-yaml.yml
    else
        echo -e "${YELLOW}Elastic Stack deployment file not found, skipping...${NC}"
    fi
    
    print_step "Deploying Ingress..."
    if [ -f "ansible/deploy-ingress.yml" ]; then
        ansible-playbook -i ansible/hosts ansible/deploy-ingress.yml --extra-vars "env=$ENV namespace=$NAMESPACE"
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

# Function to verify deployment
verify_deployment() {
    print_section "🔍 VERIFYING DEPLOYMENT"
    
    print_step "Checking deployments..."
    kubectl get deployments -n $NAMESPACE
    
    print_step "Checking services..."
    kubectl get services -n $NAMESPACE
    
    print_step "Checking pods..."
    kubectl get pods -n $NAMESPACE
    
    print_step "Checking HPA..."
    kubectl get hpa -n $NAMESPACE
    
    print_step "Checking PDB..."
    kubectl get pdb -n $NAMESPACE
    
    print_step "Checking ingress..."
    kubectl get ingress -n $NAMESPACE
    
    echo -e "${GREEN}✅ Deployment verification completed${NC}"
}

# Function to wait for services to be ready
wait_for_services() {
    print_section "⏳ WAITING FOR SERVICES TO BE READY"
    
    print_step "Waiting for all pods to be ready..."
    
    # Wait for all deployments to be ready
    deployments=$(kubectl get deployments -n $NAMESPACE -o jsonpath='{.items[*].metadata.name}')
    
    for deployment in $deployments; do
        echo "Waiting for deployment $deployment to be ready..."
        kubectl rollout status deployment/$deployment -n $NAMESPACE --timeout=300s
    done
    
    # Wait for all pods to be ready
    echo "Waiting for all pods to be ready..."
    kubectl wait --for=condition=ready pod --all -n $NAMESPACE --timeout=600s
    
    echo -e "${GREEN}✅ All services are ready${NC}"
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
    
    print_step "Resource Counts:"
    deployments=$(kubectl get deployments -n $NAMESPACE --no-headers | wc -l)
    services=$(kubectl get services -n $NAMESPACE --no-headers | wc -l)
    pods=$(kubectl get pods -n $NAMESPACE --no-headers | wc -l)
    hpa=$(kubectl get hpa -n $NAMESPACE --no-headers 2>/dev/null | wc -l || echo "0")
    pdb=$(kubectl get pdb -n $NAMESPACE --no-headers 2>/dev/null | wc -l || echo "0")
    
    echo "Deployments: $deployments"
    echo "Services: $services"
    echo "Pods: $pods"
    echo "HPA: $hpa"
    echo "PDB: $pdb"
    
    print_step "Monitoring Commands:"
    echo "kubectl get pods -n $NAMESPACE"
    echo "kubectl get hpa -n $NAMESPACE"
    echo "kubectl get pdb -n $NAMESPACE"
    echo "kubectl top pods -n $NAMESPACE"
    echo "kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp'"
    
    echo -e "${GREEN}🎉 Full environment rebuild completed successfully!${NC}"
}

# Function to handle errors
handle_error() {
    echo -e "${RED}❌ Error occurred during rebuild process${NC}"
    echo -e "${RED}Error details: $1${NC}"
    echo -e "${YELLOW}You may need to manually clean up resources${NC}"
    exit 1
}

# Main execution
main() {
    echo -e "${BLUE}🚀 FULL ENVIRONMENT REBUILD SCRIPT${NC}"
    echo "=========================================="
    echo "Environment: $ENV"
    echo "Image Tag: $IMAGE_TAG"
    echo "Namespace: $NAMESPACE"
    echo "Jenkins Trigger: $JENKINS_TRIGGER"
    if [ "$JENKINS_TRIGGER" = "true" ]; then
        echo "Jenkins URL: $JENKINS_URL"
    fi
    echo "=========================================="
    
    # Set error handling
    trap 'handle_error "$BASH_COMMAND"' ERR
    
    # Check prerequisites
    check_kubectl
    check_namespace
    
    # Execute rebuild process
    cleanup_environment
    wait_for_cleanup
    deploy_infrastructure
    deploy_all_services
    deploy_hpa_pdb
    trigger_jenkins_jobs
    wait_for_services
    verify_deployment
    show_final_status
}

# Show usage if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [environment] [image_tag] [namespace] [jenkins_trigger] [jenkins_url] [jenkins_user] [jenkins_password] [jenkins_token]"
    echo ""
    echo "Parameters:"
    echo "  environment        Environment name (default: dev)"
    echo "  image_tag          Docker image tag (default: latest)"
    echo "  namespace          Kubernetes namespace (default: default)"
    echo "  jenkins_trigger    Enable Jenkins triggers (default: true)"
    echo "  jenkins_url        Jenkins URL (default: http://192.168.1.224:8080)"
    echo "  jenkins_user       Jenkins username (default: khaled)"
    echo "  jenkins_password   Jenkins password (default: Welcome123)"
    echo "  jenkins_token      Jenkins token (default: empty)"
    echo ""
    echo "Examples:"
    echo "  $0                                    # Use all defaults"
    echo "  $0 dev latest default true            # Basic rebuild with Jenkins"
    echo "  $0 dev v1.2.3 default false           # Rebuild without Jenkins"
    echo "  $0 stg latest staging true            # Staging environment"
    echo ""
    exit 1
fi

# Run main function
main "$@" 