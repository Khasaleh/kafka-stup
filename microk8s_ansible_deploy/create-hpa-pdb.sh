#!/bin/bash

# Create HPA and PDB Script
# This script creates Horizontal Pod Autoscalers and Pod Disruption Budgets for all services

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Service categories
HIGH_USAGE_SERVICES=(
    "angular-dev"
    "angular-customer"
    "angular-business"
    "angular-ads"
    "angular-employee"
    "angular-customer-ssr"
    "api-server"
    "fazeal-business"
    "order-service"
    "catalog-service"
    "posts-service"
    "promotion-service"
    "customer-service"
)

MEDIUM_USAGE_SERVICES=(
    "payment-service"
    "notification-service"
    "loyalty-service"
    "inventory-service"
    "events-service"
    "chat-app"
    "business-chat"
    "album-service"
    "translation-service"
    "watermark-detection"
    "site-management-service"
    "shopping-service"
    "payment-gateway"
    "employees-service"
    "ads-service"
)

LOW_USAGE_SERVICES=(
    "config-server"
    "api-gateway"
    "cron-jobs"
    "dataload-service"
)

# Function to create HPA configuration
create_hpa_config() {
    local service="$1"
    local category="$2"
    
    case $category in
        "high")
            local min_replicas=2
            local max_replicas=10
            ;;
        "medium")
            local min_replicas=2
            local max_replicas=8
            ;;
        "low")
            local min_replicas=1
            local max_replicas=3
            ;;
        *)
            local min_replicas=2
            local max_replicas=5
            ;;
    esac
    
    cat > "application_deployment/dev/$service/hpa.yml" << EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: $service-hpa
  labels:
    app: $service
    component: hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: $service
  minReplicas: $min_replicas
  maxReplicas: $max_replicas
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 70
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 2
        periodSeconds: 15
      selectPolicy: Max
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
      - type: Pods
        value: 1
        periodSeconds: 60
      selectPolicy: Max
EOF
}

# Function to create PDB configuration
create_pdb_config() {
    local service="$1"
    local category="$2"
    
    case $category in
        "high")
            local min_available="50%"
            ;;
        "medium")
            local min_available="50%"
            ;;
        "low")
            local min_available="1"
            ;;
        *)
            local min_available="50%"
            ;;
    esac
    
    cat > "application_deployment/dev/$service/pdb.yml" << EOF
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: $service-pdb
  labels:
    app: $service
    component: pdb
spec:
  minAvailable: $min_available
  selector:
    matchLabels:
      app: $service
EOF
}

# Function to get service category
get_service_category() {
    local service="$1"
    
    for s in "${HIGH_USAGE_SERVICES[@]}"; do
        if [[ "$s" == "$service" ]]; then
            echo "high"
            return 0
        fi
    done
    
    for s in "${MEDIUM_USAGE_SERVICES[@]}"; do
        if [[ "$s" == "$service" ]]; then
            echo "medium"
            return 0
        fi
    done
    
    for s in "${LOW_USAGE_SERVICES[@]}"; do
        if [[ "$s" == "$service" ]]; then
            echo "low"
            return 0
        fi
    done
    
    echo "medium" # default
}

# Function to create HPA and PDB for a service
create_service_configs() {
    local service="$1"
    local category="$2"
    
    echo -e "${BLUE}Creating HPA and PDB for $service (Category: $category)...${NC}"
    
    # Create HPA
    create_hpa_config "$service" "$category"
    echo -e "${GREEN}✓ Created HPA for $service${NC}"
    
    # Create PDB
    create_pdb_config "$service" "$category"
    echo -e "${GREEN}✓ Created PDB for $service${NC}"
}

# Function to process all services
process_all_services() {
    local env="${1:-dev}"
    local base_dir="application_deployment/$env"
    
    echo -e "${YELLOW}Creating HPA and PDB configurations for all services...${NC}"
    echo "================================================================"
    
    if [ ! -d "$base_dir" ]; then
        echo -e "${RED}Error: Directory $base_dir does not exist${NC}"
        exit 1
    fi
    
    local hpa_count=0
    local pdb_count=0
    local skipped_count=0
    
    for service_dir in "$base_dir"/*; do
        if [ -d "$service_dir" ]; then
            local service=$(basename "$service_dir")
            local deployment_file="$service_dir/deployment.yml"
            
            if [ -f "$deployment_file" ]; then
                local category=$(get_service_category "$service")
                create_service_configs "$service" "$category"
                ((hpa_count++))
                ((pdb_count++))
            else
                echo -e "${YELLOW}Warning: No deployment.yml found for $service${NC}"
                ((skipped_count++))
            fi
        fi
    done
    
    echo ""
    echo -e "${GREEN}Summary:${NC}"
    echo -e "  HPA Configurations Created: $hpa_count"
    echo -e "  PDB Configurations Created: $pdb_count"
    echo -e "  Skipped: $skipped_count"
}

# Function to show HPA and PDB configurations
show_configurations() {
    echo -e "${BLUE}HPA and PDB Configuration Summary${NC}"
    echo "====================================="
    echo ""
    
    echo -e "${GREEN}High Usage Services (HPA: 2-10 replicas, PDB: 50%):${NC}"
    printf '%s\n' "${HIGH_USAGE_SERVICES[@]}"
    echo ""
    
    echo -e "${YELLOW}Medium Usage Services (HPA: 2-8 replicas, PDB: 50%):${NC}"
    printf '%s\n' "${MEDIUM_USAGE_SERVICES[@]}"
    echo ""
    
    echo -e "${RED}Low Usage Services (HPA: 1-3 replicas, PDB: 1 pod):${NC}"
    printf '%s\n' "${LOW_USAGE_SERVICES[@]}"
    echo ""
    
    echo -e "${BLUE}HPA Configuration Details:${NC}"
    echo "============================="
    echo "• CPU Utilization Target: 70%"
    echo "• Memory Utilization Target: 70%"
    echo "• Scale Up: Aggressive (100% increase, 2 pods max per 15s)"
    echo "• Scale Down: Conservative (10% decrease, 1 pod max per 60s)"
    echo "• Scale Up Stabilization: 60s"
    echo "• Scale Down Stabilization: 300s"
    echo ""
    
    echo -e "${BLUE}PDB Configuration Details:${NC}"
    echo "============================="
    echo "• High/Medium Usage: 50% of pods must remain available"
    echo "• Low Usage: At least 1 pod must remain available"
    echo "• Ensures HA during node maintenance/updates"
}

# Function to create deployment script
create_deployment_script() {
    local env="${1:-dev}"
    local script_file="deploy-hpa-pdb-$env.sh"
    
    cat > "$script_file" << 'EOF'
#!/bin/bash

# Deploy HPA and PDB Script
# This script deploys all HPA and PDB configurations

set -e

ENV=${1:-dev}
NAMESPACE=${2:-default}

echo "Deploying HPA and PDB configurations for $ENV environment..."

# Deploy PDBs first (they need to exist before scaling)
echo "Deploying Pod Disruption Budgets..."
for service in application_deployment/$ENV/*; do
    if [ -d "$service" ] && [ -f "$service/pdb.yml" ]; then
        echo "  - Deploying PDB for $(basename $service)..."
        kubectl apply -f "$service/pdb.yml" -n $NAMESPACE
    fi
done

# Deploy HPAs
echo "Deploying Horizontal Pod Autoscalers..."
for service in application_deployment/$ENV/*; do
    if [ -d "$service" ] && [ -f "$service/hpa.yml" ]; then
        echo "  - Deploying HPA for $(basename $service)..."
        kubectl apply -f "$service/hpa.yml" -n $NAMESPACE
    fi
done

echo "HPA and PDB deployment completed!"
echo ""
echo "To monitor HPA status:"
echo "  kubectl get hpa -n $NAMESPACE"
echo ""
echo "To monitor PDB status:"
echo "  kubectl get pdb -n $NAMESPACE"
EOF
    
    chmod +x "$script_file"
    echo -e "${GREEN}Deployment script created: $script_file${NC}"
}

# Function to create monitoring script
create_monitoring_script() {
    local env="${1:-dev}"
    local script_file="monitor-hpa-pdb-$env.sh"
    
    cat > "$script_file" << 'EOF'
#!/bin/bash

# Monitor HPA and PDB Script
# This script provides monitoring commands for HPA and PDB

set -e

ENV=${1:-dev}
NAMESPACE=${2:-default}

echo "HPA and PDB Monitoring Commands for $ENV environment"
echo "=================================================="
echo ""

echo "1. Check HPA Status:"
echo "   kubectl get hpa -n $NAMESPACE"
echo ""

echo "2. Check PDB Status:"
echo "   kubectl get pdb -n $NAMESPACE"
echo ""

echo "3. Check Pod Distribution:"
echo "   kubectl get pods -n $NAMESPACE -o wide"
echo ""

echo "4. Check Resource Usage:"
echo "   kubectl top pods -n $NAMESPACE"
echo ""

echo "5. Check Node Resource Usage:"
echo "   kubectl top nodes"
echo ""

echo "6. Detailed HPA Information:"
echo "   kubectl describe hpa -n $NAMESPACE"
echo ""

echo "7. Detailed PDB Information:"
echo "   kubectl describe pdb -n $NAMESPACE"
echo ""

echo "8. Check Scaling Events:"
echo "   kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | grep -i hpa"
echo ""
EOF
    
    chmod +x "$script_file"
    echo -e "${GREEN}Monitoring script created: $script_file${NC}"
}

# Main execution
main() {
    local action="${1:-create}"
    local env="${2:-dev}"
    
    case $action in
        "create")
            echo -e "${BLUE}HPA and PDB Creation Script${NC}"
            echo "================================"
            process_all_services "$env"
            create_deployment_script "$env"
            create_monitoring_script "$env"
            echo ""
            echo -e "${GREEN}HPA and PDB creation completed!${NC}"
            echo ""
            echo -e "${YELLOW}Next steps:${NC}"
            echo "  1. Review the configurations: $0 show"
            echo "  2. Deploy: ./deploy-hpa-pdb-$env.sh"
            echo "  3. Monitor: ./monitor-hpa-pdb-$env.sh"
            ;;
        "show")
            show_configurations
            ;;
        *)
            echo "Usage: $0 [action] [environment]"
            echo ""
            echo "Actions:"
            echo "  create - Create HPA and PDB configurations (default)"
            echo "  show   - Show configuration details"
            echo ""
            echo "Examples:"
            echo "  $0 create dev"
            echo "  $0 show"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 