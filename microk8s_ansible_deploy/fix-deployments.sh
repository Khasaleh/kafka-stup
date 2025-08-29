#!/bin/bash

echo "Fixing deployment files structure..."

# Function to fix a deployment file
fix_deployment() {
    local file="$1"
    local service="$2"
    
    echo "Fixing $service..."
    
    # Create a new file with correct structure
    cat > "$file.new" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $service
  labels:
    app: $service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $service
  template:
    metadata:
      labels:
        app: $service
    spec:
      imagePullSecrets:
        - name: dockerhub-secret
      containers:
        - name: $service
          image: khsaleh889/familymicroservices:\$IMAGE
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
              protocol: TCP
          env:
            - name: SERVICE_NAME
              value: "$service"
          livenessProbe:
            failureThreshold: 3
            initialDelaySeconds: 30
            periodSeconds: 10
            successThreshold: 1
            tcpSocket:
              port: 80
            timeoutSeconds: 3
          readinessProbe:
            failureThreshold: 3
            initialDelaySeconds: 5
            periodSeconds: 10
            successThreshold: 1
            tcpSocket:
              port: 80
            timeoutSeconds: 1
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
EOF
    
    # Replace the original file
    mv "$file.new" "$file"
}

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
    deployment_file="application_deployment/dev/$service/deployment.yml"
    if [ -f "$deployment_file" ]; then
        fix_deployment "$deployment_file" "$service"
    else
        echo "Warning: $deployment_file not found"
    fi
done

echo "All deployment files fixed!" 