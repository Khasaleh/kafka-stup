#!/bin/bash

# Simple Resource Update Script
# This script updates resource allocations for all services

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
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
    "search-service"
    "fazeal-logistics"
)

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

# Function to create resource template
create_resource_template() {
    local category="$1"
    local service="$2"
    local temp_file="$3"
    
    case $category in
        "high")
            cat > "$temp_file" << 'EOF'
          resources:
            requests:
              memory: "1Gi"
              cpu: "500m"
            limits:
              memory: "2Gi"
              cpu: "1000m"
          livenessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 60
            periodSeconds: 30
            timeoutSeconds: 10
            failureThreshold: 3
          readinessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
            successThreshold: 1
EOF
            ;;
        "medium")
            cat > "$temp_file" << 'EOF'
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "500m"
          livenessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 45
            periodSeconds: 30
            timeoutSeconds: 10
            failureThreshold: 3
          readinessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 20
            periodSeconds: 15
            timeoutSeconds: 5
            failureThreshold: 3
            successThreshold: 1
EOF
            ;;
        "low")
            cat > "$temp_file" << 'EOF'
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "250m"
          livenessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 30
            timeoutSeconds: 10
            failureThreshold: 3
          readinessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 15
            periodSeconds: 20
            timeoutSeconds: 5
            failureThreshold: 3
            successThreshold: 1
EOF
            ;;
    esac
}

# Function to update deployment file
update_deployment_file() {
    local service="$1"
    local deployment_file="application_deployment/dev/$service/deployment.yml"
    local category="$2"
    
    echo -e "${BLUE}Updating $service (Category: $category)...${NC}"
    
    if [ ! -f "$deployment_file" ]; then
        echo -e "${YELLOW}Warning: No deployment.yml found for $service${NC}"
        return 1
    fi
    
    # Create backup
    cp "$deployment_file" "${deployment_file}.backup"
    
    # Create temporary files
    local temp_file="/tmp/${service}_resources.yml"
    local new_deployment="/tmp/${service}_new.yml"
    
    # Generate resource template
    create_resource_template "$category" "$service" "$temp_file"
    
    # Create new deployment file
    awk '
    BEGIN { in_container = 0; resources_added = 0 }
    /^        - name:/ { in_container = 1 }
    in_container && /^          resources:/ { 
        # Skip existing resources section
        while (getline && /^            /) { }
        resources_added = 1
    }
    in_container && /^          livenessProbe:/ { 
        # Skip existing liveness probe
        while (getline && /^            /) { }
    }
    in_container && /^          readinessProbe:/ { 
        # Skip existing readiness probe
        while (getline && /^            /) { }
    }
    in_container && /^          imagePullSecrets:/ && !resources_added {
        # Insert resources before imagePullSecrets
        system("cat /tmp/'$service'_resources.yml")
        resources_added = 1
    }
    { print }
    ' "$deployment_file" > "$new_deployment"
    
    # Replace original file
    mv "$new_deployment" "$deployment_file"
    
    # Clean up
    rm -f "$temp_file"
    
    echo -e "${GREEN}✓ Updated $service${NC}"
}

# Function to process all services
process_all_services() {
    local env="${1:-dev}"
    local base_dir="application_deployment/$env"
    
    echo -e "${YELLOW}Processing services in $base_dir...${NC}"
    
    if [ ! -d "$base_dir" ]; then
        echo -e "${RED}Error: Directory $base_dir does not exist${NC}"
        exit 1
    fi
    
    for service_dir in "$base_dir"/*; do
        if [ -d "$service_dir" ]; then
            local service=$(basename "$service_dir")
            local category=$(get_service_category "$service")
            update_deployment_file "$service" "$category"
        fi
    done
}

# Function to show service categories
show_categories() {
    echo -e "${BLUE}Service Categories:${NC}"
    echo ""
    echo -e "${GREEN}High Usage Services:${NC}"
    printf '%s\n' "${HIGH_USAGE_SERVICES[@]}"
    echo ""
    echo -e "${YELLOW}Medium Usage Services:${NC}"
    printf '%s\n' "${MEDIUM_USAGE_SERVICES[@]}"
    echo ""
    echo -e "${RED}Low Usage Services:${NC}"
    printf '%s\n' "${LOW_USAGE_SERVICES[@]}"
}

# Main execution
main() {
    local action="${1:-update}"
    local env="${2:-dev}"
    
    case $action in
        "update")
            echo -e "${BLUE}Resource Allocation Update Script${NC}"
            echo "=========================================="
            process_all_services "$env"
            echo ""
            echo -e "${GREEN}Resource allocation update completed!${NC}"
            ;;
        "show")
            show_categories
            ;;
        *)
            echo "Usage: $0 [action] [environment]"
            echo ""
            echo "Actions:"
            echo "  update - Update resource allocations (default)"
            echo "  show   - Show service categories"
            echo ""
            echo "Examples:"
            echo "  $0 update dev"
            echo "  $0 show"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 