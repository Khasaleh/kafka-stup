#!/bin/bash

# Test Resource Update Script
# This script updates a single service for testing

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Service to test
SERVICE="order-service"
CATEGORY="high"

# Resource configurations
HIGH_RESOURCES="
          resources:
            requests:
              memory: \"1Gi\"
              cpu: \"500m\"
            limits:
              memory: \"2Gi\"
              cpu: \"1000m\""

HIGH_READINESS_PROBE="
          readinessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 10
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

# Function to update deployment file
update_deployment_file() {
    local service="$1"
    local deployment_file="application_deployment/dev/$service/deployment.yml"
    
    echo -e "${BLUE}Updating $service (Category: $CATEGORY)...${NC}"
    
    if [ ! -f "$deployment_file" ]; then
        echo "Error: Deployment file not found: $deployment_file"
        exit 1
    fi
    
    # Create a temporary file
    local temp_file="${deployment_file}.tmp"
    cp "$deployment_file" "$temp_file"
    
    # Remove existing resources section
    if grep -q "resources:" "$temp_file"; then
        awk '/^          resources:/ { in_resources=1; next } 
             in_resources && /^          [a-zA-Z]/ { in_resources=0 } 
             !in_resources { print }' "$temp_file" > "${temp_file}.tmp2"
        mv "${temp_file}.tmp2" "$temp_file"
    fi
    
    # Remove existing readiness probe
    if grep -q "readinessProbe:" "$temp_file"; then
        awk '/^          readinessProbe:/ { in_probe=1; next } 
             in_probe && /^          [a-zA-Z]/ { in_probe=0 } 
             !in_probe { print }' "$temp_file" > "${temp_file}.tmp2"
        mv "${temp_file}.tmp2" "$temp_file"
    fi
    
    # Remove existing liveness probe
    if grep -q "livenessProbe:" "$temp_file"; then
        awk '/^          livenessProbe:/ { in_probe=1; next } 
             in_probe && /^          [a-zA-Z]/ { in_probe=0 } 
             !in_probe { print }' "$temp_file" > "${temp_file}.tmp2"
        mv "${temp_file}.tmp2" "$temp_file"
    fi
    
    # Insert new liveness probe before readiness probe
    awk -v probe="$HIGH_LIVENESS_PROBE" '
        /readinessProbe:/ { print probe; print; next }
        { print }
    ' "$temp_file" > "${temp_file}.tmp2"
    mv "${temp_file}.tmp2" "$temp_file"
    
    # Insert new readiness probe before resources
    awk -v probe="$HIGH_READINESS_PROBE" '
        /resources:/ { print probe; print; next }
        { print }
    ' "$temp_file" > "${temp_file}.tmp2"
    mv "${temp_file}.tmp2" "$temp_file"
    
    # Insert new resources before imagePullSecrets
    awk -v resources="$HIGH_RESOURCES" '
        /imagePullSecrets:/ { print resources; print; next }
        { print }
    ' "$temp_file" > "${temp_file}.tmp2"
    mv "${temp_file}.tmp2" "$temp_file"
    
    # Replace original file
    mv "$temp_file" "$deployment_file"
    
    echo -e "${GREEN}✓ Updated $service${NC}"
}

# Main execution
echo "Test Resource Update Script"
echo "=========================="
update_deployment_file "$SERVICE"
echo ""
echo "Update completed! Check the deployment file to verify changes." 