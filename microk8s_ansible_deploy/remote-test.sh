#!/bin/bash

# Remote Testing Script
# This script SSH to the remote server and runs testing commands

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

echo -e "${BLUE}🔧 REMOTE TESTING SCRIPT${NC}"
echo "=========================================="
echo "Host: $REMOTE_HOST"
echo "User: $REMOTE_USER"
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

# Function to check if kubectl is available on remote
check_remote_kubectl() {
    echo -e "${BLUE}🔍 CHECKING REMOTE KUBECTL${NC}"
    echo "=========================================="
    
    run_remote_command "which kubectl || echo 'kubectl not found'"
    run_remote_command "kubectl version --client --short || echo 'kubectl version check failed'"
    run_remote_command "kubectl config current-context || echo 'No current context'"
    run_remote_command "kubectl config get-contexts || echo 'No contexts found'"
}

# Function to check current cluster status
check_cluster_status() {
    echo -e "${BLUE}🔍 CHECKING CLUSTER STATUS${NC}"
    echo "=========================================="
    
    run_remote_command "kubectl get nodes"
    run_remote_command "kubectl get namespaces"
    run_remote_command "kubectl get pods --all-namespaces"
}

# Function to check Elasticsearch deployment
check_elasticsearch() {
    echo -e "${BLUE}🔍 CHECKING ELASTICSEARCH DEPLOYMENT${NC}"
    echo "=========================================="
    
    run_remote_command "kubectl get pods -n elasticsearch"
    run_remote_command "kubectl get services -n elasticsearch"
    run_remote_command "kubectl get pvc -n elasticsearch"
    run_remote_command "kubectl describe pods -n elasticsearch"
}

# Function to check if rebuild scripts exist
check_rebuild_scripts() {
    echo -e "${BLUE}🔍 CHECKING REBUILD SCRIPTS${NC}"
    echo "=========================================="
    
    run_remote_command "find /root -name '*rebuild*' -type f 2>/dev/null || echo 'No rebuild scripts found'"
    run_remote_command "find /root -name '*deploy*' -type f 2>/dev/null | head -10"
    run_remote_command "ls -la /root/ 2>/dev/null || echo 'Cannot access /root'"
}

# Function to run the rebuild script
run_rebuild_script() {
    echo -e "${BLUE}🚀 RUNNING REBUILD SCRIPT${NC}"
    echo "=========================================="
    
    # First, let's find the rebuild script
    run_remote_command "find /root -name 'rebuild-full-environment.sh' -type f 2>/dev/null"
    
    # Check if we're in the right directory
    run_remote_command "pwd && ls -la"
    
    # Try to run the rebuild script
    run_remote_command "cd /root && ./rebuild-full-environment.sh dev v1.2.3 default true"
}

# Function to check for errors and fix them
check_and_fix_errors() {
    echo -e "${BLUE}🔧 CHECKING FOR ERRORS${NC}"
    echo "=========================================="
    
    # Check for common issues
    run_remote_command "kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -20"
    run_remote_command "kubectl get pods --all-namespaces | grep -E '(Pending|Failed|CrashLoopBackOff|Error)' || echo 'No problematic pods found'"
    
    # Check storage issues
    run_remote_command "kubectl get pv"
    run_remote_command "kubectl get pvc --all-namespaces"
}

# Main execution
main() {
    echo -e "${BLUE}Starting remote testing...${NC}"
    echo ""
    
    # Check remote kubectl
    check_remote_kubectl
    
    # Check cluster status
    check_cluster_status
    
    # Check Elasticsearch deployment
    check_elasticsearch
    
    # Check rebuild scripts
    check_rebuild_scripts
    
    # Check for errors
    check_and_fix_errors
    
    echo -e "${GREEN}🎉 Remote testing completed!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Review the output above for any issues"
    echo "2. If kubectl is not configured, set up the cluster connection"
    echo "3. If scripts are missing, copy them to the remote server"
    echo "4. Run the rebuild script manually if needed"
}

# Show usage if no arguments provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  kubectl     Check kubectl availability"
    echo "  cluster     Check cluster status"
    echo "  elastic     Check Elasticsearch deployment"
    echo "  scripts     Check rebuild scripts"
    echo "  rebuild     Run rebuild script"
    echo "  errors      Check for errors"
    echo "  all         Run all checks (default)"
    echo ""
    echo "Examples:"
    echo "  $0 kubectl    # Check kubectl only"
    echo "  $0 rebuild    # Run rebuild script"
    echo "  $0 all        # Run all checks"
    echo ""
    exit 1
fi

# Check if sshpass is available
if ! command -v sshpass &> /dev/null; then
    echo -e "${RED}Error: sshpass is not installed${NC}"
    echo -e "${YELLOW}Please install sshpass:${NC}"
    echo "  macOS: brew install sshpass"
    echo "  Ubuntu: sudo apt-get install sshpass"
    echo "  CentOS: sudo yum install sshpass"
    exit 1
fi

# Run based on argument
case "$1" in
    "kubectl")
        check_remote_kubectl
        ;;
    "cluster")
        check_cluster_status
        ;;
    "elastic")
        check_elasticsearch
        ;;
    "scripts")
        check_rebuild_scripts
        ;;
    "rebuild")
        run_rebuild_script
        ;;
    "errors")
        check_and_fix_errors
        ;;
    "all"|*)
        main
        ;;
esac 