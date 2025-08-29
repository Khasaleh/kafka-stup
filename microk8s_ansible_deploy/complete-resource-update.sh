#!/bin/bash

# Complete Resource Allocation Update Script
# This script updates all services with appropriate resource allocations

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

# Function to create high usage configuration
create_high_usage_config() {
    cat << 'EOF'
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
}

# Function to create medium usage configuration
create_medium_usage_config() {
    cat << 'EOF'
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
}

# Function to create low usage configuration
create_low_usage_config() {
    cat << 'EOF'
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
    
    # Create temporary file
    local temp_file="/tmp/${service}_updated.yml"
    
    # Generate configuration based on category
    case $category in
        "high")
            local config=$(create_high_usage_config)
            ;;
        "medium")
            local config=$(create_medium_usage_config)
            ;;
        "low")
            local config=$(create_low_usage_config)
            ;;
        *)
            echo -e "${RED}Unknown category: $category${NC}"
            return 1
            ;;
    esac
    
    # Process the file to replace existing sections and add new ones
    awk -v config="$config" '
    BEGIN { 
        in_container = 0
        resources_found = 0
        liveness_found = 0
        readiness_found = 0
        config_added = 0
    }
    
    # Track when we are in a container section
    /^        - name:/ { 
        in_container = 1 
        print
        next
    }
    
    # Skip existing resources section
    in_container && /^          resources:/ { 
        resources_found = 1
        while (getline && /^            /) { }
        next
    }
    
    # Skip existing liveness probe
    in_container && /^          livenessProbe:/ { 
        liveness_found = 1
        while (getline && /^            /) { }
        next
    }
    
    # Skip existing readiness probe
    in_container && /^          readinessProbe:/ { 
        readiness_found = 1
        while (getline && /^            /) { }
        next
    }
    
    # Add configuration before imagePullSecrets
    in_container && /^          imagePullSecrets:/ && !config_added {
        print config
        config_added = 1
    }
    
    # Print all other lines
    { print }
    ' "$deployment_file" > "$temp_file"
    
    # Replace original file
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
    
    local updated_count=0
    local skipped_count=0
    
    for service_dir in "$base_dir"/*; do
        if [ -d "$service_dir" ]; then
            local service=$(basename "$service_dir")
            local deployment_file="$service_dir/deployment.yml"
            
            if [ -f "$deployment_file" ]; then
                local category=$(get_service_category "$service")
                if update_deployment_file "$service" "$category"; then
                    ((updated_count++))
                else
                    ((skipped_count++))
                fi
            else
                echo -e "${YELLOW}Warning: No deployment.yml found for $service${NC}"
                ((skipped_count++))
            fi
        fi
    done
    
    echo ""
    echo -e "${GREEN}Summary:${NC}"
    echo -e "  Updated: $updated_count services"
    echo -e "  Skipped: $skipped_count services"
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

# Function to verify updates
verify_updates() {
    local env="${1:-dev}"
    local base_dir="application_deployment/$env"
    
    echo -e "${BLUE}Verifying resource allocations...${NC}"
    echo ""
    
    local high_count=0
    local medium_count=0
    local low_count=0
    local missing_count=0
    
    for service_dir in "$base_dir"/*; do
        if [ -d "$service_dir" ]; then
            local service=$(basename "$service_dir")
            local deployment_file="$service_dir/deployment.yml"
            
            if [ -f "$deployment_file" ]; then
                if grep -q "memory: \"1Gi\"" "$deployment_file"; then
                    echo -e "${GREEN}✓ $service (High Usage)${NC}"
                    ((high_count++))
                elif grep -q "memory: \"512Mi\"" "$deployment_file"; then
                    echo -e "${YELLOW}✓ $service (Medium Usage)${NC}"
                    ((medium_count++))
                elif grep -q "memory: \"256Mi\"" "$deployment_file"; then
                    echo -e "${RED}✓ $service (Low Usage)${NC}"
                    ((low_count++))
                else
                    echo -e "${YELLOW}⚠ $service (No resources configured)${NC}"
                    ((missing_count++))
                fi
            fi
        fi
    done
    
    echo ""
    echo -e "${BLUE}Verification Summary:${NC}"
    echo -e "  High Usage: $high_count services"
    echo -e "  Medium Usage: $medium_count services"
    echo -e "  Low Usage: $low_count services"
    echo -e "  Missing: $missing_count services"
}

# Function to create rollback script
create_rollback_script() {
    local env="${1:-dev}"
    local rollback_file="rollback-resources-$env.sh"
    
    cat > "$rollback_file" << EOF
#!/bin/bash
# Rollback script for resource allocations - $env environment

echo "Rolling back resource allocations for $env environment..."

for service in application_deployment/$env/*; do
    if [ -d "\$service" ]; then
        if [ -f "\$service/deployment.yml.backup" ]; then
            echo "Restoring \$service..."
            cp "\$service/deployment.yml.backup" "\$service/deployment.yml"
        fi
    fi
done

echo "Rollback completed!"
EOF
    
    chmod +x "$rollback_file"
    echo -e "${GREEN}Rollback script created: $rollback_file${NC}"
}

# Main execution
main() {
    local action="${1:-update}"
    local env="${2:-dev}"
    
    case $action in
        "update")
            echo -e "${BLUE}Complete Resource Allocation Update Script${NC}"
            echo "================================================"
            process_all_services "$env"
            echo ""
            echo -e "${GREEN}Resource allocation update completed!${NC}"
            echo ""
            echo -e "${YELLOW}Next steps:${NC}"
            echo "  1. Review the changes: $0 verify $env"
            echo "  2. Deploy the updated configurations"
            echo "  3. Monitor resource usage"
            echo "  4. Rollback if needed: ./rollback-resources-$env.sh"
            ;;
        "show")
            show_categories
            ;;
        "verify")
            verify_updates "$env"
            ;;
        "rollback")
            create_rollback_script "$env"
            ;;
        *)
            echo "Usage: $0 [action] [environment]"
            echo ""
            echo "Actions:"
            echo "  update   - Update resource allocations (default)"
            echo "  show     - Show service categories"
            echo "  verify   - Verify resource allocations"
            echo "  rollback - Create rollback script"
            echo ""
            echo "Examples:"
            echo "  $0 update dev"
            echo "  $0 show"
            echo "  $0 verify dev"
            echo "  $0 rollback dev"
            exit 1
            ;;
    esac
}

# Run main function
main "$@" 