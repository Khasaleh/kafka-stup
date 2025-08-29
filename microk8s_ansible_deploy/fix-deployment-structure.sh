#!/bin/bash

# Fix Deployment Structure Script
# This script fixes the deployment structure by moving imagePullSecrets to the correct level

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ENVIRONMENT=${1:-dev}
NAMESPACE=${2:-default}
IMAGE_TAG=${3:-v1.2.3}

echo -e "${BLUE}🔧 FIXING DEPLOYMENT STRUCTURE${NC}"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo "Image Tag: $IMAGE_TAG"
echo "=========================================="

# Function to create correct deployment file
create_correct_deployment_file() {
    local service_name="$1"
    local port="$2"
    local image_name="$3"
    local health_check_path="$4"
    
    local deployment_file="./application_deployment/$ENVIRONMENT/$service_name/deployment.yml"
    
    # Create deployment content with correct structure
    cat > "$deployment_file" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $service_name
  namespace: $NAMESPACE
  labels:
    app: $service_name
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $service_name
  template:
    metadata:
      labels:
        app: $service_name
    spec:
      imagePullSecrets:
        - name: dockerhub-secret
      containers:
        - name: $service_name
          image: $image_name:$IMAGE_TAG
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: $port
              name: http
          env:
            - name: SERVICE_NAME
              value: "$service_name"
            - name: NAMESPACE
              value: "$NAMESPACE"
            - name: PORT
              value: "$port"
            - name: SPRING_PROFILES_ACTIVE
              value: "$ENVIRONMENT"
          envFrom:
            - configMapRef:
                name: ${service_name}-config
            - secretRef:
                name: ${service_name}-secret
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: $health_check_path
              port: $port
            initialDelaySeconds: 60
            periodSeconds: 30
            timeoutSeconds: 10
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: $health_check_path
              port: $port
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
EOF
    
    echo -e "${GREEN}✓ Fixed deployment for $service_name${NC}"
}

# Fix all deployment files
echo -e "${YELLOW}Fixing deployment files...${NC}"

# Config Server
create_correct_deployment_file "config-server" "8761" "khsaleh889/config-server" "/actuator/health"

# API Gateway
create_correct_deployment_file "api-gateway" "8080" "khsaleh889/api-gateway" "/actuator/health"

# API Server
create_correct_deployment_file "api-server" "8002" "khsaleh889/familymicroservices" "/actuator/health"

# Album Service
create_correct_deployment_file "album-service" "8081" "khsaleh889/album-service" "/actuator/health"

# Ads Service
create_correct_deployment_file "ads-service" "8082" "khsaleh889/ads-service" "/actuator/health"

# Angular Services
create_correct_deployment_file "angular-ads" "4200" "khsaleh889/angular-ads" "/"
create_correct_deployment_file "angular-business" "4201" "khsaleh889/angular-business" "/"
create_correct_deployment_file "angular-customer" "4202" "khsaleh889/angular-customer" "/"
create_correct_deployment_file "angular-customer-ssr" "4203" "khsaleh889/angular-customer-ssr" "/"
create_correct_deployment_file "angular-dev" "4204" "khsaleh889/angular-dev" "/"
create_correct_deployment_file "angular-employees" "4205" "khsaleh889/angular-employees" "/"

# Business Services
create_correct_deployment_file "business-chat" "8083" "khsaleh889/business-chat" "/actuator/health"
create_correct_deployment_file "catalog-service" "8084" "khsaleh889/catalog-service" "/actuator/health"
create_correct_deployment_file "chat-app" "8085" "khsaleh889/chat-app" "/actuator/health"
create_correct_deployment_file "cron-jobs" "8086" "khsaleh889/cron-jobs" "/actuator/health"
create_correct_deployment_file "customer-service" "8087" "khsaleh889/customer-service" "/actuator/health"
create_correct_deployment_file "employees-service" "8088" "khsaleh889/employees-service" "/actuator/health"
create_correct_deployment_file "events-service" "8089" "khsaleh889/events-service" "/actuator/health"
create_correct_deployment_file "fazeal-business" "8090" "khsaleh889/fazeal-business" "/actuator/health"
create_correct_deployment_file "fazeal-business-management" "8091" "khsaleh889/fazeal-business-management" "/actuator/health"
create_correct_deployment_file "fazeal-logistics" "8092" "khsaleh889/fazeal-logistics" "/actuator/health"
create_correct_deployment_file "inventory-service" "8093" "khsaleh889/inventory-service" "/actuator/health"
create_correct_deployment_file "loyalty-service" "8094" "khsaleh889/loyalty-service" "/actuator/health"
create_correct_deployment_file "notification-service" "8095" "khsaleh889/notification-service" "/actuator/health"
create_correct_deployment_file "order-service" "8096" "khsaleh889/order-service" "/actuator/health"
create_correct_deployment_file "payment-gateway" "8097" "khsaleh889/payment-gateway" "/actuator/health"
create_correct_deployment_file "payment-service" "8098" "khsaleh889/payment-service" "/actuator/health"
create_correct_deployment_file "posts-service" "8099" "khsaleh889/posts-service" "/actuator/health"
create_correct_deployment_file "promotion-service" "8100" "khsaleh889/promotion-service" "/actuator/health"
create_correct_deployment_file "search-service" "8101" "khsaleh889/search-service" "/actuator/health"
create_correct_deployment_file "shopping-service" "8102" "khsaleh889/shopping-service" "/actuator/health"
create_correct_deployment_file "site-management-service" "8103" "khsaleh889/site-management-service" "/actuator/health"
create_correct_deployment_file "translation-service" "8104" "khsaleh889/translation-service" "/actuator/health"
create_correct_deployment_file "watermark-detection" "8105" "khsaleh889/watermark-detection" "/actuator/health"
create_correct_deployment_file "dataload-service" "8106" "khsaleh889/dataload-service" "/health"

echo ""
echo -e "${GREEN}🎉 All deployment files fixed!${NC}"

# Now deploy all deployments
echo ""
echo -e "${BLUE}🚀 DEPLOYING ALL DEPLOYMENTS${NC}"
echo "=========================================="

# Deploy all deployments
echo -e "${YELLOW}Deploying deployments...${NC}"
for service in config-server api-gateway api-server album-service ads-service angular-ads angular-business angular-customer angular-customer-ssr angular-dev angular-employees business-chat catalog-service chat-app cron-jobs customer-service employees-service events-service fazeal-business fazeal-business-management fazeal-logistics inventory-service loyalty-service notification-service order-service payment-gateway payment-service posts-service promotion-service search-service shopping-service site-management-service translation-service watermark-detection dataload-service; do
    echo "  Deploying deployment for $service..."
    kubectl apply -f "./application_deployment/$ENVIRONMENT/$service/deployment.yml"
done

echo ""
echo -e "${GREEN}🎉 All deployments deployed successfully!${NC}"
echo ""
echo -e "${YELLOW}Checking deployment status...${NC}"
kubectl get deployments -n $NAMESPACE
echo ""
echo -e "${YELLOW}Checking pod status...${NC}"
kubectl get pods -n $NAMESPACE
echo ""
echo -e "${GREEN}✅ Deployment completed!${NC}" 