#!/bin/bash

# Test Elastic Stack YAML Deployment
# This script tests the YAML-based Elastic Stack deployment

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🧪 TESTING ELASTIC STACK YAML DEPLOYMENT${NC}"
echo "=========================================="
echo ""

# Function to print step headers
print_step() {
    echo -e "${YELLOW}$1${NC}"
    echo "----------------------------------------"
}

# Check prerequisites
print_step "Checking prerequisites..."

# Check if ansible-playbook is available
if command -v ansible-playbook &> /dev/null; then
    echo -e "${GREEN}✅ ansible-playbook is available${NC}"
else
    echo -e "${RED}❌ ansible-playbook is not installed or not in PATH${NC}"
    echo -e "${YELLOW}Please install Ansible: pip install ansible${NC}"
    exit 1
fi

# Check if kubectl is available
if command -v kubectl &> /dev/null; then
    echo -e "${GREEN}✅ kubectl is available${NC}"
else
    echo -e "${YELLOW}⚠️ kubectl is not available - monitoring will be limited${NC}"
fi

# Check if required files exist
print_step "Checking required files..."

if [ -f "ansible/deploy-elastic-stack-yaml.yml" ]; then
    echo -e "${GREEN}✅ ansible/deploy-elastic-stack-yaml.yml exists${NC}"
else
    echo -e "${RED}❌ ansible/deploy-elastic-stack-yaml.yml not found${NC}"
    exit 1
fi

if [ -f "ansible/hosts" ]; then
    echo -e "${GREEN}✅ ansible/hosts exists${NC}"
else
    echo -e "${RED}❌ ansible/hosts not found${NC}"
    exit 1
fi

# Test the deployment
print_step "Testing Elastic Stack deployment..."

echo -e "${YELLOW}Running: ansible-playbook -i ansible/hosts ansible/deploy-elastic-stack-yaml.yml${NC}"

# Run the deployment
if ansible-playbook -i ansible/hosts ansible/deploy-elastic-stack-yaml.yml; then
    echo -e "${GREEN}✅ Elastic Stack deployment test completed successfully${NC}"
else
    echo -e "${RED}❌ Elastic Stack deployment test failed${NC}"
    exit 1
fi

# Verify deployment (if kubectl is available)
if command -v kubectl &> /dev/null; then
    print_step "Verifying deployment..."
    
    echo -e "${YELLOW}Checking Elasticsearch namespace...${NC}"
    kubectl get namespace elasticsearch
    
    echo -e "${YELLOW}Checking Elasticsearch pods...${NC}"
    kubectl get pods -n elasticsearch
    
    echo -e "${YELLOW}Checking Elasticsearch services...${NC}"
    kubectl get services -n elasticsearch
    
    echo -e "${YELLOW}Checking Kibana pods...${NC}"
    kubectl get pods -n elasticsearch | grep kibana
    
    echo -e "${GREEN}✅ Verification completed${NC}"
else
    echo -e "${YELLOW}Skipping verification (kubectl not available)${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Elastic Stack YAML deployment test completed successfully!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Wait for pods to be ready: kubectl get pods -n elasticsearch -w"
echo "2. Access Kibana: kubectl port-forward -n elasticsearch svc/kibana 5601:5601"
echo "3. Access Elasticsearch: kubectl port-forward -n elasticsearch svc/elasticsearch-master 9200:9200"
echo "" 