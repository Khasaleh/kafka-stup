#!/bin/bash

# Deploy All Services Script (Remote)
# This script deploys all services without Elastic Stack

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

echo -e "${BLUE}🚀 DEPLOYING ALL SERVICES${NC}"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo "Image Tag: $IMAGE_TAG"
echo "=========================================="

# Function to create deployment file
create_deployment_file() {
    local service_name="$1"
    local port="$2"
    local image_name="$3"
    local health_check_path="$4"
    
    local deployment_file="./application_deployment/$ENVIRONMENT/$service_name/deployment.yml"
    
    # Create deployment content
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
    
    echo -e "${GREEN}✓ Created deployment for $service_name${NC}"
}

# Function to create service file
create_service_file() {
    local service_name="$1"
    local port="$2"
    
    local service_file="./application_deployment/$ENVIRONMENT/$service_name/service.yml"
    
    # Create service content
    cat > "$service_file" <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $service_name
  namespace: $NAMESPACE
  labels:
    app: $service_name
spec:
  type: ClusterIP
  ports:
    - port: $port
      targetPort: $port
      protocol: TCP
      name: http
  selector:
    app: $service_name
EOF
    
    echo -e "${GREEN}✓ Created service for $service_name${NC}"
}

# Function to create configmap file
create_configmap_file() {
    local service_name="$1"
    
    local configmap_file="./application_deployment/$ENVIRONMENT/$service_name/configmap.yml"
    
    # Create configmap content
    cat > "$configmap_file" <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: ${service_name}-config
  namespace: $NAMESPACE
  labels:
    app: $service_name
data:
  SERVICE_NAME: "$service_name"
  NAMESPACE: "$NAMESPACE"
  ENVIRONMENT: "$ENVIRONMENT"
  LOG_LEVEL: "INFO"
EOF
    
    echo -e "${GREEN}✓ Created configmap for $service_name${NC}"
}

# Function to create secret file
create_secret_file() {
    local service_name="$1"
    
    local secret_file="./application_deployment/$ENVIRONMENT/$service_name/secret.yml"
    
    # Create secret content
    cat > "$secret_file" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${service_name}-secret
  namespace: $NAMESPACE
  labels:
    app: $service_name
type: Opaque
data:
  SERVICE_NAME: $(echo -n "$service_name" | base64)
  DB_HOST: $(echo -n "192.168.1.224" | base64)
  DB_PORT: $(echo -n "5432" | base64)
  DB_NAME: $(echo -n "${service_name}_db" | base64)
  DB_USER: $(echo -n "fazeal_user" | base64)
  DB_PASSWORD: $(echo -n "fazeal_password_2024" | base64)
  REDIS_PASSWORD: $(echo -n "redis_password_2024" | base64)
  JWT_SECRET: $(echo -n "jwt_secret_key_for_${service_name}_2024" | base64)
  API_KEY: $(echo -n "api_key_${service_name}_2024" | base64)
EOF
    
    echo -e "${GREEN}✓ Created secret for $service_name${NC}"
}

# Create deployment files for all services
echo -e "${YELLOW}Creating deployment files...${NC}"

# Config Server
create_deployment_file "config-server" "8761" "khsaleh889/config-server" "/actuator/health"
create_service_file "config-server" "8761"
create_configmap_file "config-server"
create_secret_file "config-server"

# API Gateway
create_deployment_file "api-gateway" "8080" "khsaleh889/api-gateway" "/actuator/health"
create_service_file "api-gateway" "8080"
create_configmap_file "api-gateway"
create_secret_file "api-gateway"

# API Server
create_deployment_file "api-server" "8002" "khsaleh889/familymicroservices" "/actuator/health"
create_service_file "api-server" "8002"
create_configmap_file "api-server"
create_secret_file "api-server"

# Album Service
create_deployment_file "album-service" "8081" "khsaleh889/album-service" "/actuator/health"
create_service_file "album-service" "8081"
create_configmap_file "album-service"
create_secret_file "album-service"

# Ads Service
create_deployment_file "ads-service" "8082" "khsaleh889/ads-service" "/actuator/health"
create_service_file "ads-service" "8082"
create_configmap_file "ads-service"
create_secret_file "ads-service"

# Angular Services
create_deployment_file "angular-ads" "4200" "khsaleh889/angular-ads" "/"
create_service_file "angular-ads" "4200"
create_configmap_file "angular-ads"
create_secret_file "angular-ads"

create_deployment_file "angular-business" "4201" "khsaleh889/angular-business" "/"
create_service_file "angular-business" "4201"
create_configmap_file "angular-business"
create_secret_file "angular-business"

create_deployment_file "angular-customer" "4202" "khsaleh889/angular-customer" "/"
create_service_file "angular-customer" "4202"
create_configmap_file "angular-customer"
create_secret_file "angular-customer"

create_deployment_file "angular-customer-ssr" "4203" "khsaleh889/angular-customer-ssr" "/"
create_service_file "angular-customer-ssr" "4203"
create_configmap_file "angular-customer-ssr"
create_secret_file "angular-customer-ssr"

create_deployment_file "angular-dev" "4204" "khsaleh889/angular-dev" "/"
create_service_file "angular-dev" "4204"
create_configmap_file "angular-dev"
create_secret_file "angular-dev"

create_deployment_file "angular-employees" "4205" "khsaleh889/angular-employees" "/"
create_service_file "angular-employees" "4205"
create_configmap_file "angular-employees"
create_secret_file "angular-employees"

# Business Services
create_deployment_file "business-chat" "8083" "khsaleh889/business-chat" "/actuator/health"
create_service_file "business-chat" "8083"
create_configmap_file "business-chat"
create_secret_file "business-chat"

create_deployment_file "catalog-service" "8084" "khsaleh889/catalog-service" "/actuator/health"
create_service_file "catalog-service" "8084"
create_configmap_file "catalog-service"
create_secret_file "catalog-service"

create_deployment_file "chat-app" "8085" "khsaleh889/chat-app" "/actuator/health"
create_service_file "chat-app" "8085"
create_configmap_file "chat-app"
create_secret_file "chat-app"

create_deployment_file "cron-jobs" "8086" "khsaleh889/cron-jobs" "/actuator/health"
create_service_file "cron-jobs" "8086"
create_configmap_file "cron-jobs"
create_secret_file "cron-jobs"

create_deployment_file "customer-service" "8087" "khsaleh889/customer-service" "/actuator/health"
create_service_file "customer-service" "8087"
create_configmap_file "customer-service"
create_secret_file "customer-service"

create_deployment_file "employees-service" "8088" "khsaleh889/employees-service" "/actuator/health"
create_service_file "employees-service" "8088"
create_configmap_file "employees-service"
create_secret_file "employees-service"

create_deployment_file "events-service" "8089" "khsaleh889/events-service" "/actuator/health"
create_service_file "events-service" "8089"
create_configmap_file "events-service"
create_secret_file "events-service"

create_deployment_file "fazeal-business" "8090" "khsaleh889/fazeal-business" "/actuator/health"
create_service_file "fazeal-business" "8090"
create_configmap_file "fazeal-business"
create_secret_file "fazeal-business"

create_deployment_file "fazeal-business-management" "8091" "khsaleh889/fazeal-business-management" "/actuator/health"
create_service_file "fazeal-business-management" "8091"
create_configmap_file "fazeal-business-management"
create_secret_file "fazeal-business-management"

create_deployment_file "fazeal-logistics" "8092" "khsaleh889/fazeal-logistics" "/actuator/health"
create_service_file "fazeal-logistics" "8092"
create_configmap_file "fazeal-logistics"
create_secret_file "fazeal-logistics"

create_deployment_file "inventory-service" "8093" "khsaleh889/inventory-service" "/actuator/health"
create_service_file "inventory-service" "8093"
create_configmap_file "inventory-service"
create_secret_file "inventory-service"

create_deployment_file "loyalty-service" "8094" "khsaleh889/loyalty-service" "/actuator/health"
create_service_file "loyalty-service" "8094"
create_configmap_file "loyalty-service"
create_secret_file "loyalty-service"

create_deployment_file "notification-service" "8095" "khsaleh889/notification-service" "/actuator/health"
create_service_file "notification-service" "8095"
create_configmap_file "notification-service"
create_secret_file "notification-service"

create_deployment_file "order-service" "8096" "khsaleh889/order-service" "/actuator/health"
create_service_file "order-service" "8096"
create_configmap_file "order-service"
create_secret_file "order-service"

create_deployment_file "payment-gateway" "8097" "khsaleh889/payment-gateway" "/actuator/health"
create_service_file "payment-gateway" "8097"
create_configmap_file "payment-gateway"
create_secret_file "payment-gateway"

create_deployment_file "payment-service" "8098" "khsaleh889/payment-service" "/actuator/health"
create_service_file "payment-service" "8098"
create_configmap_file "payment-service"
create_secret_file "payment-service"

create_deployment_file "posts-service" "8099" "khsaleh889/posts-service" "/actuator/health"
create_service_file "posts-service" "8099"
create_configmap_file "posts-service"
create_secret_file "posts-service"

create_deployment_file "promotion-service" "8100" "khsaleh889/promotion-service" "/actuator/health"
create_service_file "promotion-service" "8100"
create_configmap_file "promotion-service"
create_secret_file "promotion-service"

create_deployment_file "search-service" "8101" "khsaleh889/search-service" "/actuator/health"
create_service_file "search-service" "8101"
create_configmap_file "search-service"
create_secret_file "search-service"

create_deployment_file "shopping-service" "8102" "khsaleh889/shopping-service" "/actuator/health"
create_service_file "shopping-service" "8102"
create_configmap_file "shopping-service"
create_secret_file "shopping-service"

create_deployment_file "site-management-service" "8103" "khsaleh889/site-management-service" "/actuator/health"
create_service_file "site-management-service" "8103"
create_configmap_file "site-management-service"
create_secret_file "site-management-service"

create_deployment_file "translation-service" "8104" "khsaleh889/translation-service" "/actuator/health"
create_service_file "translation-service" "8104"
create_configmap_file "translation-service"
create_secret_file "translation-service"

create_deployment_file "watermark-detection" "8105" "khsaleh889/watermark-detection" "/actuator/health"
create_service_file "watermark-detection" "8105"
create_configmap_file "watermark-detection"
create_secret_file "watermark-detection"

create_deployment_file "dataload-service" "8106" "khsaleh889/dataload-service" "/health"
create_service_file "dataload-service" "8106"
create_configmap_file "dataload-service"
create_secret_file "dataload-service"

echo ""
echo -e "${GREEN}🎉 All deployment files created successfully!${NC}"

# Deploy all services
echo ""
echo -e "${BLUE}🚀 DEPLOYING ALL SERVICES TO KUBERNETES${NC}"
echo "=========================================="

# Create Docker Hub secret if it doesn't exist
echo -e "${YELLOW}Creating Docker Hub secret...${NC}"
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=khsaleh889 \
  --docker-password=your_password_here \
  --docker-email=your_email@example.com \
  --dry-run=client -o yaml | kubectl apply -f -

# Deploy all secrets
echo -e "${YELLOW}Deploying secrets...${NC}"
for service in config-server api-gateway api-server album-service ads-service angular-ads angular-business angular-customer angular-customer-ssr angular-dev angular-employees business-chat catalog-service chat-app cron-jobs customer-service employees-service events-service fazeal-business fazeal-business-management fazeal-logistics inventory-service loyalty-service notification-service order-service payment-gateway payment-service posts-service promotion-service search-service shopping-service site-management-service translation-service watermark-detection dataload-service; do
    echo "  Deploying secret for $service..."
    kubectl apply -f "./application_deployment/$ENVIRONMENT/$service/secret.yml"
done

# Deploy all configmaps
echo -e "${YELLOW}Deploying configmaps...${NC}"
for service in config-server api-gateway api-server album-service ads-service angular-ads angular-business angular-customer angular-customer-ssr angular-dev angular-employees business-chat catalog-service chat-app cron-jobs customer-service employees-service events-service fazeal-business fazeal-business-management fazeal-logistics inventory-service loyalty-service notification-service order-service payment-gateway payment-service posts-service promotion-service search-service shopping-service site-management-service translation-service watermark-detection dataload-service; do
    echo "  Deploying configmap for $service..."
    kubectl apply -f "./application_deployment/$ENVIRONMENT/$service/configmap.yml"
done

# Deploy all services
echo -e "${YELLOW}Deploying services...${NC}"
for service in config-server api-gateway api-server album-service ads-service angular-ads angular-business angular-customer angular-customer-ssr angular-dev angular-employees business-chat catalog-service chat-app cron-jobs customer-service employees-service events-service fazeal-business fazeal-business-management fazeal-logistics inventory-service loyalty-service notification-service order-service payment-gateway payment-service posts-service promotion-service search-service shopping-service site-management-service translation-service watermark-detection dataload-service; do
    echo "  Deploying service for $service..."
    kubectl apply -f "./application_deployment/$ENVIRONMENT/$service/service.yml"
done

# Deploy all deployments
echo -e "${YELLOW}Deploying deployments...${NC}"
for service in config-server api-gateway api-server album-service ads-service angular-ads angular-business angular-customer angular-customer-ssr angular-dev angular-employees business-chat catalog-service chat-app cron-jobs customer-service employees-service events-service fazeal-business fazeal-business-management fazeal-logistics inventory-service loyalty-service notification-service order-service payment-gateway payment-service posts-service promotion-service search-service shopping-service site-management-service translation-service watermark-detection dataload-service; do
    echo "  Deploying deployment for $service..."
    kubectl apply -f "./application_deployment/$ENVIRONMENT/$service/deployment.yml"
done

echo ""
echo -e "${GREEN}🎉 All services deployed successfully!${NC}"
echo ""
echo -e "${YELLOW}Checking deployment status...${NC}"
kubectl get deployments -n $NAMESPACE
echo ""
echo -e "${YELLOW}Checking pod status...${NC}"
kubectl get pods -n $NAMESPACE
echo ""
echo -e "${GREEN}✅ Deployment completed!${NC}" 