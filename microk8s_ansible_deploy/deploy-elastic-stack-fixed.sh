#!/bin/bash

# Fixed Elastic Stack Deployment Script
# This script deploys Elastic Stack with proper vault configuration

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ENV=${1:-dev}
NAMESPACE=${2:-default}

echo -e "${BLUE}🔧 DEPLOYING ELASTIC STACK (FIXED)${NC}"
echo "=========================================="
echo "Environment: $ENV"
echo "Namespace: $NAMESPACE"
echo "=========================================="
echo ""

# Function to print step headers
print_step() {
    echo -e "${YELLOW}$1${NC}"
    echo "----------------------------------------"
}

# Check if ansible-playbook is available
check_ansible() {
    if ! command -v ansible-playbook &> /dev/null; then
        echo -e "${RED}Error: ansible-playbook is not installed or not in PATH${NC}"
        echo -e "${YELLOW}Please install Ansible: pip install ansible${NC}"
        exit 1
    fi
}

# Deploy Elastic Stack
deploy_elastic_stack() {
    print_step "Deploying Elastic Stack (YAML-based)..."
    
    if [ -f "ansible/deploy-elastic-stack-yaml.yml" ]; then
        echo -e "${YELLOW}Running: ansible-playbook -i ansible/hosts ansible/deploy-elastic-stack-yaml.yml${NC}"
        
        ansible-playbook -i ansible/hosts ansible/deploy-elastic-stack-yaml.yml
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Elastic Stack deployment completed successfully${NC}"
        else
            echo -e "${RED}❌ Elastic Stack deployment failed${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: ansible/deploy-elastic-stack-yaml.yml not found${NC}"
        exit 1
    fi
}

# Verify deployment
verify_deployment() {
    print_step "Verifying Elastic Stack deployment..."
    
    echo -e "${YELLOW}Checking Elasticsearch pods...${NC}"
    kubectl get pods -n $NAMESPACE | grep elasticsearch || echo "No Elasticsearch pods found"
    
    echo -e "${YELLOW}Checking Kibana pods...${NC}"
    kubectl get pods -n $NAMESPACE | grep kibana || echo "No Kibana pods found"
    
    echo -e "${YELLOW}Checking Elasticsearch services...${NC}"
    kubectl get services -n $NAMESPACE | grep elasticsearch || echo "No Elasticsearch services found"
    
    echo -e "${GREEN}✅ Verification completed${NC}"
}

# Main execution
main() {
    # Check prerequisites
    check_ansible
    
    # Deploy Elastic Stack
    deploy_elastic_stack
    
    # Verify deployment
    verify_deployment
    
    echo -e "${GREEN}🎉 Elastic Stack deployment completed!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Wait for pods to be ready: kubectl get pods -n $NAMESPACE -w"
    echo "2. Access Kibana: kubectl port-forward -n $NAMESPACE svc/kibana-kibana 5601:5601"
    echo "3. Access Elasticsearch: kubectl port-forward -n $NAMESPACE svc/elasticsearch-master 9200:9200"
}

# Show usage if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [environment] [namespace]"
    echo ""
    echo "Parameters:"
    echo "  environment    Environment name (default: dev)"
    echo "  namespace      Kubernetes namespace (default: default)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Use defaults"
    echo "  $0 dev default        # Deploy to dev environment"
    echo "  $0 stg staging        # Deploy to staging environment"
    echo ""
    exit 1
fi

# Run main function
main "$@" 