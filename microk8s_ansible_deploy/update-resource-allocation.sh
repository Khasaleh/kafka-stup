#!/bin/bash

# Resource Allocation Update Script
# This script updates CPU, memory, and health probe configurations for all services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Resource configurations
HIGH_RESOURCES="
          resources:
            requests:
              memory: \"1Gi\"
              cpu: \"500m\"
            limits:
              memory: \"2Gi\"
              cpu: \"1000m\""

MEDIUM_RESOURCES="
          resources:
            requests:
              memory: \"512Mi\"
              cpu: \"250m\"
            limits:
              memory: \"1Gi\"
              cpu: \"500m\""

LOW_RESOURCES="
          resources:
            requests:
              memory: \"256Mi\"
              cpu: \"100m\"
            limits:
              memory: \"512Mi\"
              cpu: \"250m\""

# Health probe configurations
HIGH_READINESS_PROBE="
          readinessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
            successThreshold: 1"

MEDIUM_READINESS_PROBE="
          readinessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 20
            periodSeconds: 15
            timeoutSeconds: 5
            failureThreshold: 3
            successThreshold: 1"

LOW_READINESS_PROBE="
          readinessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 15
            periodSeconds: 20
            timeoutSeconds: 5
            failureThreshold: 3
            successThreshold: 1"

HIGH_LIVENESS_PROBE="
          livenessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 60
            periodSeconds: 30
            timeoutSeconds: 10
            failureThreshold: 3"

MEDIUM_LIVENESS_PROBE="
          livenessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 45
            periodSeconds: 30
            timeoutSeconds: 10
            failureThreshold: 3"

LOW_LIVENESS_PROBE="
          livenessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 30
            timeoutSeconds: 10
            failureThreshold: 3"

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

# Function to update deployment file
update_deployment_file() {
    local service="$1"
    local deployment_file="$2"
    local category="$3"
    
    echo -e "${BLUE}Updating $service (Category: $category)...${NC}"
    
    # Create backup
    cp "$deployment_file" "${deployment_file}.backup"
    
    # Determine resources and probes based on category
    case $category in
        "high")
            resources="$HIGH_RESOURCES"
            readiness_probe="$HIGH_READINESS_PROBE"
            liveness_probe="$HIGH_LIVENESS_PROBE"
            ;;
        "medium")
            resources="$MEDIUM_RESOURCES"
            readiness_probe="$MEDIUM_READINESS_PROBE"
            liveness_probe="$MEDIUM_LIVENESS_PROBE"
            ;;
        "low")
            resources="$LOW_RESOURCES"
            readiness_probe="$LOW_READINESS_PROBE"
            liveness_probe="$LOW_LIVENESS_PROBE"
            ;;
    esac
    
    # Create a temporary file for the updated content
    local temp_file="${deployment_file}.tmp"
    cp "$deployment_file" "$temp_file"
    
    # Update resources
    if grep -q "resources:" "$temp_file"; then
        # Remove existing resources section
        awk '/^          resources:/ { in_resources=1; next } 
             in_resources && /^          [a-zA-Z]/ { in_resources=0 } 
             !in_resources { print }' "$temp_file" > "${temp_file}.tmp2"
        mv "${temp_file}.tmp2" "$temp_file"
    fi
    
    # Insert new resources before imagePullSecrets
    awk -v resources="$resources" '
        /imagePullSecrets:/ { print resources; print; next }
        { print }
    ' "$temp_file" > "${temp_file}.tmp2"
    mv "${temp_file}.tmp2" "$temp_file"
    
    # Update readiness probe
    if grep -q "readinessProbe:" "$temp_file"; then
        # Remove existing readiness probe
        awk '/^          readinessProbe:/ { in_probe=1; next } 
             in_probe && /^          [a-zA-Z]/ { in_probe=0 } 
             !in_probe { print }' "$temp_file" > "${temp_file}.tmp2"
        mv "${temp_file}.tmp2" "$temp_file"
    fi
    
    # Insert new readiness probe before resources
    awk -v probe="$readiness_probe" '
        /resources:/ { print probe; print; next }
        { print }
    ' "$temp_file" > "${temp_file}.tmp2"
    mv "${temp_file}.tmp2" "$temp_file"
    
    # Update liveness probe
    if grep -q "livenessProbe:" "$temp_file"; then
        # Remove existing liveness probe
        awk '/^          livenessProbe:/ { in_probe=1; next } 
             in_probe && /^          [a-zA-Z]/ { in_probe=0 } 
             !in_probe { print }' "$temp_file" > "${temp_file}.tmp2"
        mv "${temp_file}.tmp2" "$temp_file"
    fi
    
    # Insert new liveness probe before readiness probe
    awk -v probe="$liveness_probe" '
        /readinessProbe:/ { print probe; print; next }
        { print }
    ' "$temp_file" > "${temp_file}.tmp2"
    mv "${temp_file}.tmp2" "$temp_file"
    
    # Replace original file with updated content
    mv "$temp_file" "$deployment_file"
    
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
            local deployment_file="$service_dir/deployment.yml"
            
            if [ -f "$deployment_file" ]; then
                local category=$(get_service_category "$service")
                update_deployment_file "$service" "$deployment_file" "$category"
            else
                echo -e "${YELLOW}Warning: No deployment.yml found for $service${NC}"
            fi
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