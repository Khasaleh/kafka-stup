#!/bin/bash

# Continue Rebuild From Stuck State
# This script continues the rebuild from where it got stuck

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

echo -e "${BLUE}🔄 CONTINUING REBUILD FROM STUCK STATE${NC}"
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

# Function to clean up duplicate Elasticsearch deployments
cleanup_duplicates() {
    echo -e "${BLUE}🧹 CLEANING UP DUPLICATE DEPLOYMENTS${NC}"
    echo "=========================================="
    
    # Clean up duplicate Elasticsearch in default namespace
    run_remote_command "kubectl delete deployment elasticsearch -n default --ignore-not-found=true"
    run_remote_command "kubectl delete service elasticsearch -n default --ignore-not-found=true"
    run_remote_command "kubectl delete configmap elasticsearch-config -n default --ignore-not-found=true"
    
    # Clean up duplicate Kibana in default namespace
    run_remote_command "kubectl delete deployment kibana -n default --ignore-not-found=true"
    run_remote_command "kubectl delete service kibana -n default --ignore-not-found=true"
    run_remote_command "kubectl delete configmap kibana-config -n default --ignore-not-found=true"
    
    # Wait for cleanup
    run_remote_command "kubectl get pods -n default | grep -E '(elasticsearch|kibana)' || echo 'No duplicate pods found'"
    
    echo -e "${GREEN}✅ Duplicate cleanup completed${NC}"
}

# Function to verify infrastructure is ready
verify_infrastructure() {
    echo -e "${BLUE}🔍 VERIFYING INFRASTRUCTURE${NC}"
    echo "=========================================="
    
    # Check Elasticsearch in elasticsearch namespace
    run_remote_command "kubectl get pods -n elasticsearch"
    run_remote_command "kubectl get services -n elasticsearch"
    
    # Check Ingress
    run_remote_command "kubectl get pods -n ingress-nginx"
    run_remote_command "kubectl get services -n ingress-nginx"
    
    # Check if infrastructure is ready
    run_remote_command "kubectl get pods --all-namespaces | grep -E '(elasticsearch|ingress)' | grep -v kube-system"
    
    echo -e "${GREEN}✅ Infrastructure verification completed${NC}"
}

# Function to deploy all services
deploy_all_services() {
    echo -e "${BLUE}🚀 DEPLOYING ALL SERVICES${NC}"
    echo "=========================================="
    
    # Copy the new deployment script to remote
    echo -e "${YELLOW}Copying deployment script to remote...${NC}"
    sshpass -p "$REMOTE_PASS" scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null deploy-full-applications-skip-elastic.sh "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/"
    
    # Make it executable on remote
    run_remote_command "cd $REMOTE_DIR && chmod +x deploy-full-applications-skip-elastic.sh"
    
    # Change to remote directory and run service deployment with the new script
    run_remote_command "cd $REMOTE_DIR && ./deploy-full-applications-skip-elastic.sh dev v1.2.3 default true"
    
    echo -e "${GREEN}✅ All services deployment completed${NC}"
}

# Function to deploy HPA and PDB
deploy_hpa_pdb() {
    echo -e "${BLUE}📈 DEPLOYING HPA AND PDB${NC}"
    echo "=========================================="
    
    # Check if HPA/PDB deployment script exists
    run_remote_command "cd $REMOTE_DIR && ls -la deploy-hpa-pdb-*.sh || echo 'HPA/PDB script not found'"
    
    # Deploy HPA and PDB if script exists
    run_remote_command "cd $REMOTE_DIR && [ -f deploy-hpa-pdb-dev.sh ] && ./deploy-hpa-pdb-dev.sh dev default || echo 'Skipping HPA/PDB deployment'"
    
    echo -e "${GREEN}✅ HPA and PDB deployment completed${NC}"
}

# Function to trigger Jenkins jobs
trigger_jenkins_jobs() {
    echo -e "${BLUE}🔄 TRIGGERING JENKINS JOBS${NC}"
    echo "=========================================="
    
    # Check if Jenkins trigger script exists
    run_remote_command "cd $REMOTE_DIR && ls -la jenkins-trigger.sh || echo 'Jenkins trigger script not found'"
    
    # Trigger Jenkins jobs if script exists
    run_remote_command "cd $REMOTE_DIR && [ -f jenkins-trigger.sh ] && ./jenkins-trigger.sh applications http://192.168.1.224:8080 khaled Welcome123 '' dev v1.2.3 || echo 'Skipping Jenkins jobs'"
    
    echo -e "${GREEN}✅ Jenkins jobs triggered${NC}"
}

# Function to wait for services to be ready
wait_for_services() {
    echo -e "${BLUE}⏳ WAITING FOR SERVICES TO BE READY${NC}"
    echo "=========================================="
    
    # Wait for all deployments to be ready
    run_remote_command "kubectl get deployments --all-namespaces | grep -v kube-system"
    
    # Wait for all pods to be ready
    run_remote_command "kubectl get pods --all-namespaces | grep -v kube-system | grep -v elasticsearch"
    
    echo -e "${GREEN}✅ Services ready check completed${NC}"
}

# Function to show final status
show_final_status() {
    echo -e "${BLUE}📊 FINAL STATUS${NC}"
    echo "=========================================="
    
    run_remote_command "kubectl get pods --all-namespaces | grep -v kube-system"
    run_remote_command "kubectl get services --all-namespaces | grep -v kube-system"
    run_remote_command "kubectl get deployments --all-namespaces | grep -v kube-system"
    run_remote_command "kubectl get hpa --all-namespaces"
    run_remote_command "kubectl get pdb --all-namespaces"
    
    echo -e "${GREEN}✅ Final status check completed${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting rebuild continuation...${NC}"
    echo ""
    
    # Clean up duplicates
    cleanup_duplicates
    
    # Verify infrastructure
    verify_infrastructure
    
    # Deploy all services
    deploy_all_services
    
    # Deploy HPA and PDB
    deploy_hpa_pdb
    
    # Trigger Jenkins jobs
    trigger_jenkins_jobs
    
    # Wait for services
    wait_for_services
    
    # Show final status
    show_final_status
    
    echo -e "${GREEN}🎉 Rebuild continuation completed!${NC}"
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

# Run main function
main 