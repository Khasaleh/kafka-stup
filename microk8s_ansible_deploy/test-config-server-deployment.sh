#!/bin/bash

# Test Config Server Deployment
# This script tests the config-server deployment manually

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

REMOTE_HOST="192.168.1.225"
REMOTE_USER="root"
REMOTE_PASS="Infotec1212!@"
REMOTE_DIR="/root/microk8s_ansible_deploy"

echo -e "${BLUE}🧪 TESTING CONFIG SERVER DEPLOYMENT${NC}"
echo "=========================================="
echo "Host: $REMOTE_HOST"
echo "User: $REMOTE_USER"
echo "Remote Directory: $REMOTE_DIR"
echo "=========================================="

# Function to run remote command
run_remote_command() {
    local command="$1"
    echo -e "${YELLOW}Running: $command${NC}"
    echo "----------------------------------------"
    
    sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$REMOTE_USER@$REMOTE_HOST" "$command"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Command completed successfully${NC}"
    else
        echo -e "${RED}❌ Command failed${NC}"
    fi
    echo ""
}

# Test the deployment files
echo -e "${BLUE}🔍 TESTING DEPLOYMENT FILES${NC}"
echo "=========================================="

# Check if files exist
run_remote_command "cd $REMOTE_DIR && ls -la application_deployment/dev/config-server/"

# Check file sizes
run_remote_command "cd $REMOTE_DIR && wc -l application_deployment/dev/config-server/*.yml"

# Check file contents
run_remote_command "cd $REMOTE_DIR && head -10 application_deployment/dev/config-server/deployment.yml"

# Test kubectl apply
echo -e "${BLUE}🚀 TESTING KUBECTL APPLY${NC}"
echo "=========================================="

# Apply config-server deployment
run_remote_command "cd $REMOTE_DIR && kubectl apply -f application_deployment/dev/config-server/deployment.yml"

# Check if deployment was created
run_remote_command "kubectl get deployment config-server -n default"

# Check if pod was created
run_remote_command "kubectl get pods -n default | grep config-server"

# Check pod status
run_remote_command "kubectl describe pod -n default -l app=config-server"

echo -e "${GREEN}🎉 Config server deployment test completed!${NC}" 