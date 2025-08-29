#!/bin/bash

echo "Fixing deployment files structure..."

# List of all services
SERVICES=(
    "api-server"
    "site-management-service"
    "shopping-service"
    "posts-service"
    "payment-gateway"
    "order-service"
    "notification-service"
    "loyalty-service"
    "inventory-service"
    "fazeal-business-management"
    "fazeal-business"
    "events-service"
    "angular-customer-ssr"
    "cron-jobs"
    "chat-app"
    "business-chat"
    "api-gateway"
    "angular-dev"
    "angular-customer"
    "angular-business"
    "angular-ads"
    "angular-employee"
    "album-service"
    "ads-service"
    "promotion-service"
    "catalog-service"
    "customer-service"
    "employees-service"
    "payment-service"
    "translation-service"
    "watermark-detection"
)

for service in "${SERVICES[@]}"; do
    echo "Fixing $service deployment..."
    
    deployment_file="application_deployment/dev/$service/deployment.yml"
    
    if [ -f "$deployment_file" ]; then
        # Create a temporary file
        temp_file=$(mktemp)
        
        # Process the file to fix the structure
        awk '
        BEGIN { in_container = 0; in_spec = 0; }
        /^      containers:/ { in_spec = 1; print; next; }
        /^        - name:/ { in_container = 1; print; next; }
        /^          [a-zA-Z]/ && in_container && !/^          (name|image|ports|env|livenessProbe|readinessProbe|resources):/ {
            # This is a field that should be at pod spec level, not container level
            if (/^          (dnsPolicy|imagePullSecrets|restartPolicy|terminationGracePeriodSeconds):/) {
                # Remove the extra indentation to move it to pod spec level
                gsub(/^          /, "      ")
                in_container = 0
            }
        }
        /^      [a-zA-Z]/ && in_spec && !in_container {
            # We're back at pod spec level
            in_container = 0
        }
        { print }
        ' "$deployment_file" > "$temp_file"
        
        # Replace the original file
        mv "$temp_file" "$deployment_file"
        
        echo "Fixed $service"
    else
        echo "Warning: $deployment_file not found"
    fi
done

echo "All deployment files fixed!" 