#!/bin/bash

echo "Creating missing configmap, secret, and service files..."

# List of all services
SERVICES=(
    "config-server"
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

# Function to create configmap file
create_configmap() {
    local service="$1"
    local file="application_deployment/dev/$service/configmap.yml"
    
    echo "Creating configmap for $service..."
    
    cat > "$file" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: $service-config
  namespace: default
  labels:
    app: $service
data:
  SERVICE_NAME: "$service"
  DEPLOYMENT_MODE: "service-specific"
EOF
}

# Function to create secret file
create_secret() {
    local service="$1"
    local file="application_deployment/dev/$service/secret.yml"
    
    echo "Creating secret for $service..."
    
    cat > "$file" << EOF
apiVersion: v1
kind: Secret
metadata:
  name: $service-secret
  namespace: default
  labels:
    app: $service
type: Opaque
data:
  SERVICE_NAME: "$(echo -n "$service" | base64)"
  DEPLOYMENT_MODE: "$(echo -n "service-specific" | base64)"
EOF
}

# Function to create service file
create_service() {
    local service="$1"
    local file="application_deployment/dev/$service/service.yml"
    
    echo "Creating service for $service..."
    
    cat > "$file" << EOF
apiVersion: v1
kind: Service
metadata:
  name: $service
  namespace: default
  labels:
    app: $service
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
      name: http
  selector:
    app: $service
EOF
}

# Create files for all services
for service in "${SERVICES[@]}"; do
    # Create directory if it doesn't exist
    mkdir -p "application_deployment/dev/$service"
    
    # Create configmap if it doesn't exist
    if [ ! -f "application_deployment/dev/$service/configmap.yml" ]; then
        create_configmap "$service"
    else
        echo "Configmap for $service already exists"
    fi
    
    # Create secret if it doesn't exist
    if [ ! -f "application_deployment/dev/$service/secret.yml" ]; then
        create_secret "$service"
    else
        echo "Secret for $service already exists"
    fi
    
    # Create service if it doesn't exist
    if [ ! -f "application_deployment/dev/$service/service.yml" ]; then
        create_service "$service"
    else
        echo "Service for $service already exists"
    fi
done

echo "All files created!" 