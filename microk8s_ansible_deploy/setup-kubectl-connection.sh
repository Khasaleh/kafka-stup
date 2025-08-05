#!/bin/bash

# Setup kubectl connection to remote Kubernetes cluster
# This script helps configure kubectl to connect to the remote cluster

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 SETTING UP KUBECTL CONNECTION${NC}"
echo "=========================================="
echo ""

# Function to print step headers
print_step() {
    echo -e "${YELLOW}$1${NC}"
    echo "----------------------------------------"
}

# Check if kubectl is available
check_kubectl() {
    if command -v kubectl &> /dev/null; then
        echo -e "${GREEN}✅ kubectl is available${NC}"
        return 0
    else
        echo -e "${RED}❌ kubectl is not installed${NC}"
        echo -e "${YELLOW}Please install kubectl first: brew install kubectl${NC}"
        return 1
    fi
}

# Check current kubectl context
check_current_context() {
    print_step "Checking current kubectl configuration..."
    
    if kubectl config current-context 2>/dev/null; then
        echo -e "${GREEN}✅ kubectl context is configured${NC}"
        kubectl config view --minify
    else
        echo -e "${YELLOW}⚠️ No kubectl context configured${NC}"
    fi
}

# Test cluster connectivity
test_cluster_connectivity() {
    print_step "Testing cluster connectivity..."
    
    if kubectl cluster-info 2>/dev/null; then
        echo -e "${GREEN}✅ Successfully connected to cluster${NC}"
        return 0
    else
        echo -e "${RED}❌ Cannot connect to cluster${NC}"
        return 1
    fi
}

# Show connection options
show_connection_options() {
    print_step "Connection Options"
    
    echo -e "${YELLOW}To connect to the remote Kubernetes cluster, you need to:${NC}"
    echo ""
    echo "1. **Get kubeconfig from master node (192.168.1.200):**"
    echo "   ssh root@192.168.1.200 'microk8s config' > ~/.kube/config"
    echo ""
    echo "2. **Or copy kubeconfig from master node:**"
    echo "   scp root@192.168.1.200:/root/.kube/config ~/.kube/config"
    echo ""
    echo "3. **Or use kubectl proxy if you have access:**"
    echo "   kubectl proxy --address=0.0.0.0 --port=8080"
    echo ""
    echo "4. **Or set KUBECONFIG environment variable:**"
    echo "   export KUBECONFIG=/path/to/your/kubeconfig"
    echo ""
    echo -e "${YELLOW}Which method would you like to use?${NC}"
}

# Setup connection from master node
setup_from_master() {
    print_step "Setting up connection from master node..."
    
    echo -e "${YELLOW}Attempting to get kubeconfig from master node (192.168.1.200)...${NC}"
    
    # Create .kube directory if it doesn't exist
    mkdir -p ~/.kube
    
    # Try to get kubeconfig from master node
    if ssh -o ConnectTimeout=10 root@192.168.1.200 'microk8s config' > ~/.kube/config 2>/dev/null; then
        echo -e "${GREEN}✅ Successfully retrieved kubeconfig from master node${NC}"
        chmod 600 ~/.kube/config
        return 0
    else
        echo -e "${RED}❌ Failed to connect to master node or get kubeconfig${NC}"
        echo -e "${YELLOW}Please check:${NC}"
        echo "1. SSH access to 192.168.1.200"
        echo "2. Root user access"
        echo "3. MicroK8s is running on the master node"
        return 1
    fi
}

# Test the connection
test_connection() {
    print_step "Testing connection..."
    
    if test_cluster_connectivity; then
        echo -e "${GREEN}✅ Cluster connection successful!${NC}"
        echo ""
        echo -e "${YELLOW}Cluster information:${NC}"
        kubectl cluster-info
        echo ""
        echo -e "${YELLOW}Available nodes:${NC}"
        kubectl get nodes
        echo ""
        echo -e "${YELLOW}Available namespaces:${NC}"
        kubectl get namespaces
        return 0
    else
        echo -e "${RED}❌ Cluster connection failed${NC}"
        return 1
    fi
}

# Main execution
main() {
    # Check kubectl
    if ! check_kubectl; then
        exit 1
    fi
    
    # Check current context
    check_current_context
    
    # Test current connectivity
    if test_cluster_connectivity; then
        echo -e "${GREEN}🎉 kubectl is already properly configured!${NC}"
        return 0
    fi
    
    # Show connection options
    show_connection_options
    
    # Try to setup from master node
    if setup_from_master; then
        if test_connection; then
            echo -e "${GREEN}🎉 kubectl connection setup completed successfully!${NC}"
            return 0
        fi
    fi
    
    echo -e "${YELLOW}Please manually configure kubectl connection using one of the methods above.${NC}"
    echo -e "${YELLOW}Once configured, run this script again to verify the connection.${NC}"
    return 1
}

# Run main function
main "$@" 