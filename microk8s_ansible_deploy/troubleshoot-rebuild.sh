#!/bin/bash

# Troubleshoot Rebuild Script
# This script helps troubleshoot and continue a stuck rebuild process

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 TROUBLESHOOTING REBUILD PROCESS${NC}"
echo "=========================================="
echo ""

# Function to check kubectl
check_kubectl() {
    echo -e "${YELLOW}Checking kubectl availability...${NC}"
    if command -v kubectl &> /dev/null; then
        echo -e "${GREEN}✅ kubectl is available${NC}"
        return 0
    else
        echo -e "${RED}❌ kubectl is not available${NC}"
        echo -e "${YELLOW}Please install kubectl or ensure it's in your PATH${NC}"
        return 1
    fi
}

# Function to check cluster connectivity
check_cluster() {
    echo -e "${YELLOW}Checking cluster connectivity...${NC}"
    if kubectl cluster-info &> /dev/null; then
        echo -e "${GREEN}✅ Cluster is accessible${NC}"
        return 0
    else
        echo -e "${RED}❌ Cannot connect to cluster${NC}"
        echo -e "${YELLOW}Please check your kubeconfig and cluster status${NC}"
        return 1
    fi
}

# Function to check namespace status
check_namespace() {
    local namespace=${1:-default}
    echo -e "${YELLOW}Checking namespace $namespace...${NC}"
    
    if kubectl get namespace $namespace &> /dev/null; then
        echo -e "${GREEN}✅ Namespace $namespace exists${NC}"
        
        # Check for stuck resources
        echo -e "${YELLOW}Checking for stuck resources...${NC}"
        
        # Check for stuck pods
        stuck_pods=$(kubectl get pods -n $namespace --field-selector=status.phase!=Running,status.phase!=Succeeded,status.phase!=Failed 2>/dev/null | grep -v "No resources found" | wc -l || echo "0")
        if [ "$stuck_pods" -gt 0 ]; then
            echo -e "${RED}⚠️ Found $stuck_pods stuck pods${NC}"
            kubectl get pods -n $namespace --field-selector=status.phase!=Running,status.phase!=Succeeded,status.phase!=Failed 2>/dev/null || true
        else
            echo -e "${GREEN}✅ No stuck pods found${NC}"
        fi
        
        # Check for stuck PVCs
        stuck_pvcs=$(kubectl get pvc -n $namespace --field-selector=status.phase!=Bound 2>/dev/null | grep -v "No resources found" | wc -l || echo "0")
        if [ "$stuck_pvcs" -gt 0 ]; then
            echo -e "${RED}⚠️ Found $stuck_pvcs stuck PVCs${NC}"
            kubectl get pvc -n $namespace --field-selector=status.phase!=Bound 2>/dev/null || true
        else
            echo -e "${GREEN}✅ No stuck PVCs found${NC}"
        fi
        
        return 0
    else
        echo -e "${RED}❌ Namespace $namespace does not exist${NC}"
        return 1
    fi
}

# Function to force cleanup stuck resources
force_cleanup() {
    local namespace=${1:-default}
    echo -e "${YELLOW}Force cleaning up stuck resources in namespace $namespace...${NC}"
    
    # Force delete stuck pods
    echo -e "${YELLOW}Force deleting stuck pods...${NC}"
    kubectl delete pods --all -n $namespace --force --grace-period=0 2>/dev/null || true
    
    # Force delete stuck PVCs
    echo -e "${YELLOW}Force deleting stuck PVCs...${NC}"
    kubectl delete pvc --all -n $namespace --force --grace-period=0 2>/dev/null || true
    
    # Force delete stuck PVs
    echo -e "${YELLOW}Force deleting stuck PVs...${NC}"
    kubectl delete pv --all --force --grace-period=0 2>/dev/null || true
    
    # Force delete stuck deployments
    echo -e "${YELLOW}Force deleting stuck deployments...${NC}"
    kubectl delete deployments --all -n $namespace --force --grace-period=0 2>/dev/null || true
    
    echo -e "${GREEN}✅ Force cleanup completed${NC}"
}

# Function to check if rebuild can continue
check_rebuild_status() {
    local namespace=${1:-default}
    echo -e "${YELLOW}Checking if rebuild can continue...${NC}"
    
    # Check if namespace is clean
    pod_count=$(kubectl get pods -n $namespace --no-headers 2>/dev/null | wc -l || echo "0")
    deployment_count=$(kubectl get deployments -n $namespace --no-headers 2>/dev/null | wc -l || echo "0")
    service_count=$(kubectl get services -n $namespace --no-headers 2>/dev/null | wc -l || echo "0")
    
    echo "Current resources in namespace $namespace:"
    echo "  Pods: $pod_count"
    echo "  Deployments: $deployment_count"
    echo "  Services: $service_count"
    
    if [ "$pod_count" -eq 0 ] && [ "$deployment_count" -eq 0 ] && [ "$service_count" -eq 0 ]; then
        echo -e "${GREEN}✅ Namespace is clean, rebuild can continue${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ Namespace still has resources, may need force cleanup${NC}"
        return 1
    fi
}

# Function to provide recovery options
show_recovery_options() {
    echo ""
    echo -e "${BLUE}🔄 RECOVERY OPTIONS${NC}"
    echo "=========================================="
    echo ""
    echo -e "${YELLOW}Option 1: Continue with current rebuild${NC}"
    echo "  ./rebuild-full-environment.sh dev v1.2.3 default true"
    echo ""
    echo -e "${YELLOW}Option 2: Force cleanup and restart${NC}"
    echo "  ./troubleshoot-rebuild.sh force-cleanup"
    echo "  ./rebuild-full-environment.sh dev v1.2.3 default true"
    echo ""
    echo -e "${YELLOW}Option 3: Skip cleanup and deploy only${NC}"
    echo "  ./deploy-full-applications.sh dev v1.2.3 default true"
    echo ""
    echo -e "${YELLOW}Option 4: Deploy HPA and PDB only${NC}"
    echo "  ./deploy-hpa-pdb-dev.sh dev default"
    echo ""
    echo -e "${YELLOW}Option 5: Manual cleanup and restart${NC}"
    echo "  kubectl delete all --all -n default"
    echo "  kubectl delete pvc --all -n default"
    echo "  kubectl delete pv --all"
    echo "  ./rebuild-full-environment.sh dev v1.2.3 default true"
    echo ""
}

# Function to provide manual cleanup commands
show_manual_cleanup() {
    echo ""
    echo -e "${BLUE}🔧 MANUAL CLEANUP COMMANDS${NC}"
    echo "=========================================="
    echo ""
    echo "If the script is stuck, run these commands manually:"
    echo ""
    echo -e "${YELLOW}1. Check current status:${NC}"
    echo "   kubectl get all -n default"
    echo "   kubectl get pvc -n default"
    echo "   kubectl get pv"
    echo ""
    echo -e "${YELLOW}2. Force delete all resources:${NC}"
    echo "   kubectl delete all --all -n default --force --grace-period=0"
    echo "   kubectl delete pvc --all -n default --force --grace-period=0"
    echo "   kubectl delete pv --all --force --grace-period=0"
    echo "   kubectl delete hpa --all -n default --force --grace-period=0"
    echo "   kubectl delete pdb --all -n default --force --grace-period=0"
    echo ""
    echo -e "${YELLOW}3. Wait for cleanup:${NC}"
    echo "   kubectl get pods -n default"
    echo "   # Repeat until no pods are shown"
    echo ""
    echo -e "${YELLOW}4. Restart rebuild:${NC}"
    echo "   ./rebuild-full-environment.sh dev v1.2.3 default true"
    echo ""
}

# Main execution
main() {
    local action="${1:-check}"
    local namespace="${2:-default}"
    
    case $action in
        "check")
            echo -e "${BLUE}🔍 DIAGNOSTIC CHECK${NC}"
            echo "=========================================="
            
            # Check kubectl
            if ! check_kubectl; then
                show_manual_cleanup
                exit 1
            fi
            
            # Check cluster
            if ! check_cluster; then
                show_manual_cleanup
                exit 1
            fi
            
            # Check namespace
            check_namespace "$namespace"
            
            # Check rebuild status
            check_rebuild_status "$namespace"
            
            show_recovery_options
            ;;
            
        "force-cleanup")
            echo -e "${BLUE}🧹 FORCE CLEANUP${NC}"
            echo "=========================================="
            
            if ! check_kubectl; then
                echo -e "${RED}Cannot perform cleanup without kubectl${NC}"
                exit 1
            fi
            
            if ! check_cluster; then
                echo -e "${RED}Cannot perform cleanup without cluster access${NC}"
                exit 1
            fi
            
            force_cleanup "$namespace"
            check_rebuild_status "$namespace"
            ;;
            
        "manual")
            show_manual_cleanup
            ;;
            
        *)
            echo "Usage: $0 [action] [namespace]"
            echo ""
            echo "Actions:"
            echo "  check         - Run diagnostic check (default)"
            echo "  force-cleanup - Force cleanup stuck resources"
            echo "  manual        - Show manual cleanup commands"
            echo ""
            echo "Examples:"
            echo "  $0 check default"
            echo "  $0 force-cleanup default"
            echo "  $0 manual"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 