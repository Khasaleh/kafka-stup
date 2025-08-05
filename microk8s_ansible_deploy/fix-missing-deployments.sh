#!/bin/bash

# Fix Missing Deployments Script
# This script creates proper deployment files for all services

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

echo -e "${BLUE}🔧 FIXING MISSING DEPLOYMENTS${NC}"
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
          imagePullSecrets:
            - name: dockerhub-secret
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

# Define services with their configurations
declare -A services=(
    ["config-server"]="8761:khsaleh889/config-server:/actuator/health"
    ["api-gateway"]="8080:khsaleh889/api-gateway:/actuator/health"
    ["api-server"]="8002:khsaleh889/familymicroservices:/actuator/health"
    ["album-service"]="8081:khsaleh889/album-service:/actuator/health"
    ["ads-service"]="8082:khsaleh889/ads-service:/actuator/health"
    ["angular-ads"]="4200:khsaleh889/angular-ads:/"
    ["angular-business"]="4201:khsaleh889/angular-business:/"
    ["angular-customer"]="4202:khsaleh889/angular-customer:/"
    ["angular-customer-ssr"]="4203:khsaleh889/angular-customer-ssr:/"
    ["angular-dev"]="4204:khsaleh889/angular-dev:/"
    ["angular-employees"]="4205:khsaleh889/angular-employees:/"
    ["business-chat"]="8083:khsaleh889/business-chat:/actuator/health"
    ["catalog-service"]="8084:khsaleh889/catalog-service:/actuator/health"
    ["chat-app"]="8085:khsaleh889/chat-app:/actuator/health"
    ["cron-jobs"]="8086:khsaleh889/cron-jobs:/actuator/health"
    ["customer-service"]="8087:khsaleh889/customer-service:/actuator/health"
    ["employees-service"]="8088:khsaleh889/employees-service:/actuator/health"
    ["events-service"]="8089:khsaleh889/events-service:/actuator/health"
    ["fazeal-business"]="8090:khsaleh889/fazeal-business:/actuator/health"
    ["fazeal-business-management"]="8091:khsaleh889/fazeal-business-management:/actuator/health"
    ["fazeal-logistics"]="8092:khsaleh889/fazeal-logistics:/actuator/health"
    ["inventory-service"]="8093:khsaleh889/inventory-service:/actuator/health"
    ["loyalty-service"]="8094:khsaleh889/loyalty-service:/actuator/health"
    ["notification-service"]="8095:khsaleh889/notification-service:/actuator/health"
    ["order-service"]="8096:khsaleh889/order-service:/actuator/health"
    ["payment-gateway"]="8097:khsaleh889/payment-gateway:/actuator/health"
    ["payment-service"]="8098:khsaleh889/payment-service:/actuator/health"
    ["posts-service"]="8099:khsaleh889/posts-service:/actuator/health"
    ["promotion-service"]="8100:khsaleh889/promotion-service:/actuator/health"
    ["search-service"]="8101:khsaleh889/search-service:/actuator/health"
    ["shopping-service"]="8102:khsaleh889/shopping-service:/actuator/health"
    ["site-management-service"]="8103:khsaleh889/site-management-service:/actuator/health"
    ["translation-service"]="8104:khsaleh889/translation-service:/actuator/health"
    ["watermark-detection"]="8105:khsaleh889/watermark-detection:/actuator/health"
    ["dataload-service"]="8106:khsaleh889/dataload-service:/health"
)

# Create deployment files for all services
echo -e "${YELLOW}Creating deployment files...${NC}"
for service in "${!services[@]}"; do
    IFS=':' read -r port image_name health_check_path <<< "${services[$service]}"
    
    # Create directory if it doesn't exist
    mkdir -p "./application_deployment/$ENVIRONMENT/$service"
    
    # Create deployment file
    create_deployment_file "$service" "$port" "$image_name" "$health_check_path"
    
    # Create service file
    create_service_file "$service" "$port"
    
    # Create configmap file
    create_configmap_file "$service"
    
    # Create secret file
    create_secret_file "$service"
done

echo ""
echo -e "${GREEN}🎉 All deployment files created successfully!${NC}"
echo ""
echo -e "${YELLOW}Summary:${NC}"
echo "- Created deployment files for ${#services[@]} services"
echo "- Each service has: deployment.yml, service.yml, configmap.yml, secret.yml"
echo "- All files include proper resource limits and health checks"
echo "- Secrets contain basic database credentials (update as needed)"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Review the generated files"
echo "2. Update image names and tags as needed"
echo "3. Update database credentials in secrets"
echo "4. Deploy the services to the cluster"
echo ""
echo -e "${RED}⚠️  Important:${NC}"
echo "- Update the database credentials with real values"
echo "- Verify image names and tags are correct"
echo "- Test deployments in a staging environment first" 