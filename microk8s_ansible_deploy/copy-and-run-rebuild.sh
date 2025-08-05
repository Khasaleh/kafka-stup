#!/bin/bash

# Copy and Run Full Rebuild Script
# This script copies the rebuild files to the remote server and runs the full environment rebuild

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

echo -e "${BLUE}🚀 COPYING AND RUNNING FULL REBUILD${NC}"
echo "=========================================="
echo "Host: $REMOTE_HOST"
echo "User: $REMOTE_USER"
echo "Remote Directory: $REMOTE_DIR"
echo "=========================================="
echo ""

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

# Function to copy files to remote server
copy_files_to_remote() {
    echo -e "${BLUE}📁 COPYING FILES TO REMOTE SERVER${NC}"
    echo "=========================================="
    
    # Create remote directory
    run_remote_command "mkdir -p $REMOTE_DIR"
    
    # Copy the entire microk8s_ansible_deploy directory
    echo -e "${YELLOW}Copying files to remote server...${NC}"
    sshpass -p "$REMOTE_PASS" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r . "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Files copied successfully${NC}"
    else
        echo -e "${RED}❌ File copy failed${NC}"
        exit 1
    fi
    
    # Set permissions on remote
    run_remote_command "chmod +x $REMOTE_DIR/*.sh"
    run_remote_command "chmod +x $REMOTE_DIR/ansible/*.yml"
    
    echo -e "${GREEN}✅ File copy and setup completed${NC}"
}

# Function to verify files on remote
verify_remote_files() {
    echo -e "${BLUE}🔍 VERIFYING REMOTE FILES${NC}"
    echo "=========================================="
    
    run_remote_command "ls -la $REMOTE_DIR/"
    run_remote_command "ls -la $REMOTE_DIR/ansible/"
    run_remote_command "which ansible-playbook || echo 'ansible-playbook not found'"
    run_remote_command "kubectl version --client --short || echo 'kubectl version check failed'"
    
    echo -e "${GREEN}✅ Remote file verification completed${NC}"
}

# Function to run the full rebuild
run_full_rebuild() {
    echo -e "${BLUE}🚀 RUNNING FULL ENVIRONMENT REBUILD${NC}"
    echo "=========================================="
    
    # Change to remote directory and run rebuild
    run_remote_command "cd $REMOTE_DIR && ./rebuild-full-environment.sh dev v1.2.3 default true"
    
    echo -e "${GREEN}✅ Full rebuild completed${NC}"
}

# Function to monitor the rebuild progress
monitor_rebuild() {
    echo -e "${BLUE}📊 MONITORING REBUILD PROGRESS${NC}"
    echo "=========================================="
    
    run_remote_command "kubectl get pods --all-namespaces"
    run_remote_command "kubectl get services --all-namespaces"
    run_remote_command "kubectl get deployments --all-namespaces"
    
    echo -e "${GREEN}✅ Monitoring completed${NC}"
}

# Function to show final status
show_final_status() {
    echo -e "${BLUE}📊 FINAL STATUS${NC}"
    echo "=========================================="
    
    run_remote_command "kubectl get pods --all-namespaces | grep -v kube-system"
    run_remote_command "kubectl get services --all-namespaces | grep -v kube-system"
    run_remote_command "kubectl get hpa --all-namespaces"
    run_remote_command "kubectl get pdb --all-namespaces"
    
    echo -e "${GREEN}✅ Final status check completed${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting full environment rebuild process...${NC}"
    echo ""
    
    # Copy files to remote
    copy_files_to_remote
    
    # Verify files on remote
    verify_remote_files
    
    # Run full rebuild
    run_full_rebuild
    
    # Monitor progress
    monitor_rebuild
    
    # Show final status
    show_final_status
    
    echo -e "${GREEN}🎉 Full environment rebuild process completed!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Check all services are running: kubectl get pods --all-namespaces"
    echo "2. Access applications through ingress or port-forward"
    echo "3. Monitor logs for any issues: kubectl logs -f <pod-name> -n <namespace>"
    echo "4. Check Jenkins jobs status if triggered"
    echo ""
}

# Check if sshpass is available
if ! command -v sshpass &> /dev/null; then
    echo -e "${RED}Error: sshpass is not installed${NC}"
    echo -e "${YELLOW}Please install sshpass:${NC}"
    echo "  macOS: brew install sshpass"
    echo "  Ubuntu: sudo apt-get install sshpass"
    echo "  CentOS: sudo yum install sshpass"
    exit 1
fi

# Check if scp is available
if ! command -v scp &> /dev/null; then
    echo -e "${RED}Error: scp is not available${NC}"
    exit 1
fi

# Run main function
main 