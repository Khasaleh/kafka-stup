#!/bin/bash

# Manual Resource Update Script
# This script manually updates each service with appropriate resource allocations

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Manual Resource Allocation Update${NC}"
echo "====================================="

# Function to update high usage service
update_high_usage_service() {
    local service="$1"
    local file="application_deployment/dev/$service/deployment.yml"
    
    echo -e "${BLUE}Updating $service (High Usage)...${NC}"
    
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}File not found: $file${NC}"
        return 1
    fi
    
    # Create backup
    cp "$file" "$file.backup"
    
    # Add resources section before imagePullSecrets
    sed -i.bak '/imagePullSecrets:/i\
          resources:\
            requests:\
              memory: "1Gi"\
              cpu: "500m"\
            limits:\
              memory: "2Gi"\
              cpu: "1000m"\
          livenessProbe:\
            tcpSocket:\
              port: 80\
            initialDelaySeconds: 60\
            periodSeconds: 30\
            timeoutSeconds: 10\
            failureThreshold: 3\
          readinessProbe:\
            tcpSocket:\
              port: 80\
            initialDelaySeconds: 30\
            periodSeconds: 10\
            timeoutSeconds: 5\
            failureThreshold: 3\
            successThreshold: 1' "$file"
    
    rm -f "$file.bak"
    echo -e "${GREEN}✓ Updated $service${NC}"
}

# Function to update medium usage service
update_medium_usage_service() {
    local service="$1"
    local file="application_deployment/dev/$service/deployment.yml"
    
    echo -e "${BLUE}Updating $service (Medium Usage)...${NC}"
    
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}File not found: $file${NC}"
        return 1
    fi
    
    # Create backup
    cp "$file" "$file.backup"
    
    # Add resources section before imagePullSecrets
    sed -i.bak '/imagePullSecrets:/i\
          resources:\
            requests:\
              memory: "512Mi"\
              cpu: "250m"\
            limits:\
              memory: "1Gi"\
              cpu: "500m"\
          livenessProbe:\
            tcpSocket:\
              port: 80\
            initialDelaySeconds: 45\
            periodSeconds: 30\
            timeoutSeconds: 10\
            failureThreshold: 3\
          readinessProbe:\
            tcpSocket:\
              port: 80\
            initialDelaySeconds: 20\
            periodSeconds: 15\
            timeoutSeconds: 5\
            failureThreshold: 3\
            successThreshold: 1' "$file"
    
    rm -f "$file.bak"
    echo -e "${GREEN}✓ Updated $service${NC}"
}

# Function to update low usage service
update_low_usage_service() {
    local service="$1"
    local file="application_deployment/dev/$service/deployment.yml"
    
    echo -e "${BLUE}Updating $service (Low Usage)...${NC}"
    
    if [ ! -f "$file" ]; then
        echo -e "${YELLOW}File not found: $file${NC}"
        return 1
    fi
    
    # Create backup
    cp "$file" "$file.backup"
    
    # Add resources section before imagePullSecrets
    sed -i.bak '/imagePullSecrets:/i\
          resources:\
            requests:\
              memory: "256Mi"\
              cpu: "100m"\
            limits:\
              memory: "512Mi"\
              cpu: "250m"\
          livenessProbe:\
            tcpSocket:\
              port: 80\
            initialDelaySeconds: 30\
            periodSeconds: 30\
            timeoutSeconds: 10\
            failureThreshold: 3\
          readinessProbe:\
            tcpSocket:\
              port: 80\
            initialDelaySeconds: 15\
            periodSeconds: 20\
            timeoutSeconds: 5\
            failureThreshold: 3\
            successThreshold: 1' "$file"
    
    rm -f "$file.bak"
    echo -e "${GREEN}✓ Updated $service${NC}"
}

# Update High Usage Services
echo ""
echo -e "${YELLOW}Updating High Usage Services...${NC}"
echo "====================================="

update_high_usage_service "angular-dev"
update_high_usage_service "angular-customer"
update_high_usage_service "angular-business"
update_high_usage_service "angular-ads"
update_high_usage_service "angular-employee"
update_high_usage_service "angular-customer-ssr"
update_high_usage_service "api-server"
update_high_usage_service "fazeal-business"
update_high_usage_service "order-service"
update_high_usage_service "catalog-service"
update_high_usage_service "posts-service"
update_high_usage_service "promotion-service"
update_high_usage_service "customer-service"

# Update Medium Usage Services
echo ""
echo -e "${YELLOW}Updating Medium Usage Services...${NC}"
echo "======================================="

update_medium_usage_service "payment-service"
update_medium_usage_service "notification-service"
update_medium_usage_service "loyalty-service"
update_medium_usage_service "inventory-service"
update_medium_usage_service "events-service"
update_medium_usage_service "chat-app"
update_medium_usage_service "business-chat"
update_medium_usage_service "album-service"
update_medium_usage_service "translation-service"
update_medium_usage_service "watermark-detection"
update_medium_usage_service "site-management-service"
update_medium_usage_service "shopping-service"
update_medium_usage_service "payment-gateway"
update_medium_usage_service "employees-service"
update_medium_usage_service "ads-service"

# Update Low Usage Services
echo ""
echo -e "${YELLOW}Updating Low Usage Services...${NC}"
echo "===================================="

update_low_usage_service "config-server"
update_low_usage_service "api-gateway"
update_low_usage_service "cron-jobs"
update_low_usage_service "dataload-service"
update_low_usage_service "search-service"
update_low_usage_service "fazeal-logistics"

echo ""
echo -e "${GREEN}Resource allocation update completed!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Verify the changes"
echo "  2. Deploy the updated configurations"
echo "  3. Monitor resource usage" 