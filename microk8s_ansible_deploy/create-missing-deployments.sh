#!/bin/bash

echo "Creating missing deployment files..."

# List of all services that need deployment files
SERVICES=(
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
    "album-service"
    "ads-service"
    "promotion-service"
)

# Function to create deployment file
create_deployment() {
    local service="$1"
    local file="application_deployment/dev/$service/deployment.yml"
    
    echo "Creating deployment for $service..."
    
    # Create directory if it doesn't exist
    mkdir -p "application_deployment/dev/$service"
    
    # Create deployment file
    cat > "$file" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $service
  namespace: default
  labels:
    app: $service
spec:
  replicas: 1
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      app: $service
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 25%
      maxUnavailable: 25%
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
            - name: spring.profiles.active
              value: "dev"
          livenessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 3
            successThreshold: 1
            failureThreshold: 3
          readinessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 5
            periodSeconds: 10
            timeoutSeconds: 1
            successThreshold: 1
            failureThreshold: 3
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"
      dnsPolicy: ClusterFirst
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
EOF
}

# Create deployment files for missing services
for service in "${SERVICES[@]}"; do
    if [ ! -f "application_deployment/dev/$service/deployment.yml" ]; then
        create_deployment "$service"
    else
        echo "Deployment file for $service already exists"
    fi
done

echo "All deployment files created!" 