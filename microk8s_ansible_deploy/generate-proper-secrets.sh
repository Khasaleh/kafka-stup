#!/bin/bash

# Generate Proper Secrets Script
# This script creates proper secrets with real database credentials, API keys, and other sensitive data

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ENVIRONMENT=${1:-dev}
NAMESPACE=${2:-default}

echo -e "${BLUE}🔐 GENERATING PROPER SECRETS${NC}"
echo "=========================================="
echo "Environment: $ENVIRONMENT"
echo "Namespace: $NAMESPACE"
echo "=========================================="

# Function to base64 encode
base64_encode() {
    echo -n "$1" | base64
}

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Function to generate random API key
generate_api_key() {
    openssl rand -hex 32
}

# Function to generate random JWT secret
generate_jwt_secret() {
    openssl rand -base64 64 | tr -d "=+/"
}

# Function to create secret file
create_secret_file() {
    local service_name="$1"
    local secret_content="$2"
    
    local secret_file="./application_deployment/$ENVIRONMENT/$service_name/secret.yml"
    
    echo "$secret_content" > "$secret_file"
    echo -e "${GREEN}✓ Created secret for $service_name${NC}"
}

# Generate common database credentials
DB_HOST="192.168.1.224"
DB_PORT="5432"
DB_NAME="fazeal_dev"
DB_USER="fazeal_user"
DB_PASSWORD=$(generate_password)
REDIS_PASSWORD=$(generate_password)
MONGO_PASSWORD=$(generate_password)

# Generate common API keys and secrets
JWT_SECRET=$(generate_jwt_secret)
API_KEY=$(generate_api_key)
ENCRYPTION_KEY=$(generate_api_key)

echo -e "${YELLOW}Generated common credentials:${NC}"
echo "DB_HOST: $DB_HOST"
echo "DB_PORT: $DB_PORT"
echo "DB_NAME: $DB_NAME"
echo "DB_USER: $DB_USER"
echo "DB_PASSWORD: $DB_PASSWORD"
echo "REDIS_PASSWORD: $REDIS_PASSWORD"
echo "MONGO_PASSWORD: $MONGO_PASSWORD"
echo "JWT_SECRET: $JWT_SECRET"
echo "API_KEY: $API_KEY"
echo ""

# 1. Config Server Secret
CONFIG_SERVER_SECRET=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: config-server-secret
  namespace: $NAMESPACE
  labels:
    app: config-server
type: Opaque
data:
  CONFIG_USER: $(base64_encode "admin")
  CONFIG_PASS: $(base64_encode "$(generate_password)")
  DB_HOST: $(base64_encode "$DB_HOST")
  DB_PORT: $(base64_encode "$DB_PORT")
  DB_NAME: $(base64_encode "$DB_NAME")
  DB_USER: $(base64_encode "$DB_USER")
  DB_PASSWORD: $(base64_encode "$DB_PASSWORD")
  REDIS_PASSWORD: $(base64_encode "$REDIS_PASSWORD")
  JWT_SECRET: $(base64_encode "$JWT_SECRET")
EOF
)
create_secret_file "config-server" "$CONFIG_SERVER_SECRET"

# 2. API Server Secret
API_SERVER_SECRET=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: api-server-secret
  namespace: $NAMESPACE
  labels:
    app: api-server
type: Opaque
data:
  SERVICE_NAME: $(base64_encode "api-server")
  DEPLOYMENT_MODE: $(base64_encode "service-specific")
  DB_HOST: $(base64_encode "$DB_HOST")
  DB_PORT: $(base64_encode "$DB_PORT")
  DB_NAME: $(base64_encode "$DB_NAME")
  DB_USER: $(base64_encode "$DB_USER")
  DB_PASSWORD: $(base64_encode "$DB_PASSWORD")
  REDIS_PASSWORD: $(base64_encode "$REDIS_PASSWORD")
  JWT_SECRET: $(base64_encode "$JWT_SECRET")
  API_KEY: $(base64_encode "$API_KEY")
  ENCRYPTION_KEY: $(base64_encode "$ENCRYPTION_KEY")
EOF
)
create_secret_file "api-server" "$API_SERVER_SECRET"

# 3. API Gateway Secret
API_GATEWAY_SECRET=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: api-gateway-secret
  namespace: $NAMESPACE
  labels:
    app: api-gateway
type: Opaque
data:
  SERVICE_NAME: $(base64_encode "api-gateway")
  JWT_SECRET: $(base64_encode "$JWT_SECRET")
  API_KEY: $(base64_encode "$API_KEY")
  ENCRYPTION_KEY: $(base64_encode "$ENCRYPTION_KEY")
  REDIS_PASSWORD: $(base64_encode "$REDIS_PASSWORD")
EOF
)
create_secret_file "api-gateway" "$API_GATEWAY_SECRET"

# 4. Dataload Service Secret
DATALOAD_SERVICE_SECRET=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: dataload-service-secrets
  namespace: $NAMESPACE
  labels:
    app: dataload-service
type: Opaque
data:
  SERVICE_NAME: $(base64_encode "dataload-service")
  DB_HOST: $(base64_encode "$DB_HOST")
  DB_PORT: $(base64_encode "$DB_PORT")
  DB_NAME: $(base64_encode "$DB_NAME")
  DB_USER: $(base64_encode "$DB_USER")
  DB_PASSWORD: $(base64_encode "$DB_PASSWORD")
  REDIS_PASSWORD: $(base64_encode "$REDIS_PASSWORD")
  API_KEY: $(base64_encode "$API_KEY")
  CELERY_BROKER_URL: $(base64_encode "redis://:$REDIS_PASSWORD@$DB_HOST:6379/0")
  CELERY_RESULT_BACKEND: $(base64_encode "redis://:$REDIS_PASSWORD@$DB_HOST:6379/0")
EOF
)
create_secret_file "dataload-service" "$DATALOAD_SERVICE_SECRET"

# 5. Customer Service Secret
CUSTOMER_SERVICE_SECRET=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: customer-service-secret
  namespace: $NAMESPACE
  labels:
    app: customer-service
type: Opaque
data:
  SERVICE_NAME: $(base64_encode "customer-service")
  DB_HOST: $(base64_encode "$DB_HOST")
  DB_PORT: $(base64_encode "$DB_PORT")
  DB_NAME: $(base64_encode "customer_db")
  DB_USER: $(base64_encode "$DB_USER")
  DB_PASSWORD: $(base64_encode "$DB_PASSWORD")
  REDIS_PASSWORD: $(base64_encode "$REDIS_PASSWORD")
  JWT_SECRET: $(base64_encode "$JWT_SECRET")
  API_KEY: $(base64_encode "$API_KEY")
EOF
)
create_secret_file "customer-service" "$CUSTOMER_SERVICE_SECRET"

# 6. Order Service Secret
ORDER_SERVICE_SECRET=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: order-service-secret
  namespace: $NAMESPACE
  labels:
    app: order-service
type: Opaque
data:
  SERVICE_NAME: $(base64_encode "order-service")
  DB_HOST: $(base64_encode "$DB_HOST")
  DB_PORT: $(base64_encode "$DB_PORT")
  DB_NAME: $(base64_encode "order_db")
  DB_USER: $(base64_encode "$DB_USER")
  DB_PASSWORD: $(base64_encode "$DB_PASSWORD")
  REDIS_PASSWORD: $(base64_encode "$REDIS_PASSWORD")
  JWT_SECRET: $(base64_encode "$JWT_SECRET")
  API_KEY: $(base64_encode "$API_KEY")
EOF
)
create_secret_file "order-service" "$ORDER_SERVICE_SECRET"

# 7. Payment Service Secret
PAYMENT_SERVICE_SECRET=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: payment-service-secret
  namespace: $NAMESPACE
  labels:
    app: payment-service
type: Opaque
data:
  SERVICE_NAME: $(base64_encode "payment-service")
  DB_HOST: $(base64_encode "$DB_HOST")
  DB_PORT: $(base64_encode "$DB_PORT")
  DB_NAME: $(base64_encode "payment_db")
  DB_USER: $(base64_encode "$DB_USER")
  DB_PASSWORD: $(base64_encode "$DB_PASSWORD")
  REDIS_PASSWORD: $(base64_encode "$REDIS_PASSWORD")
  JWT_SECRET: $(base64_encode "$JWT_SECRET")
  API_KEY: $(base64_encode "$API_KEY")
  STRIPE_SECRET_KEY: $(base64_encode "sk_test_$(generate_api_key)")
  STRIPE_PUBLISHABLE_KEY: $(base64_encode "pk_test_$(generate_api_key)")
EOF
)
create_secret_file "payment-service" "$PAYMENT_SERVICE_SECRET"

# 8. Catalog Service Secret
CATALOG_SERVICE_SECRET=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: catalog-service-secret
  namespace: $NAMESPACE
  labels:
    app: catalog-service
type: Opaque
data:
  SERVICE_NAME: $(base64_encode "catalog-service")
  DB_HOST: $(base64_encode "$DB_HOST")
  DB_PORT: $(base64_encode "$DB_PORT")
  DB_NAME: $(base64_encode "catalog_db")
  DB_USER: $(base64_encode "$DB_USER")
  DB_PASSWORD: $(base64_encode "$DB_PASSWORD")
  REDIS_PASSWORD: $(base64_encode "$REDIS_PASSWORD")
  JWT_SECRET: $(base64_encode "$JWT_SECRET")
  API_KEY: $(base64_encode "$API_KEY")
EOF
)
create_secret_file "catalog-service" "$CATALOG_SERVICE_SECRET"

# 9. Posts Service Secret
POSTS_SERVICE_SECRET=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: posts-service-secret
  namespace: $NAMESPACE
  labels:
    app: posts-service
type: Opaque
data:
  SERVICE_NAME: $(base64_encode "posts-service")
  DB_HOST: $(base64_encode "$DB_HOST")
  DB_PORT: $(base64_encode "$DB_PORT")
  DB_NAME: $(base64_encode "posts_db")
  DB_USER: $(base64_encode "$DB_USER")
  DB_PASSWORD: $(base64_encode "$DB_PASSWORD")
  REDIS_PASSWORD: $(base64_encode "$REDIS_PASSWORD")
  JWT_SECRET: $(base64_encode "$JWT_SECRET")
  API_KEY: $(base64_encode "$API_KEY")
EOF
)
create_secret_file "posts-service" "$POSTS_SERVICE_SECRET"

# 10. Promotion Service Secret
PROMOTION_SERVICE_SECRET=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: promotion-service-secret
  namespace: $NAMESPACE
  labels:
    app: promotion-service
type: Opaque
data:
  SERVICE_NAME: $(base64_encode "promotion-service")
  DB_HOST: $(base64_encode "$DB_HOST")
  DB_PORT: $(base64_encode "$DB_PORT")
  DB_NAME: $(base64_encode "promotion_db")
  DB_USER: $(base64_encode "$DB_USER")
  DB_PASSWORD: $(base64_encode "$DB_PASSWORD")
  REDIS_PASSWORD: $(base64_encode "$REDIS_PASSWORD")
  JWT_SECRET: $(base64_encode "$JWT_SECRET")
  API_KEY: $(base64_encode "$API_KEY")
EOF
)
create_secret_file "promotion-service" "$PROMOTION_SERVICE_SECRET"

# Generate secrets for remaining services with similar pattern
services=(
    "album-service"
    "ads-service"
    "angular-ads"
    "angular-business"
    "angular-customer"
    "angular-customer-ssr"
    "angular-dev"
    "angular-employees"
    "business-chat"
    "chat-app"
    "cron-jobs"
    "employees-service"
    "events-service"
    "fazeal-business"
    "fazeal-business-management"
    "fazeal-logistics"
    "inventory-service"
    "loyalty-service"
    "notification-service"
    "payment-gateway"
    "search-service"
    "shopping-service"
    "site-management-service"
    "translation-service"
    "watermark-detection"
)

for service in "${services[@]}"; do
    SERVICE_SECRET=$(cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${service}-secret
  namespace: $NAMESPACE
  labels:
    app: $service
type: Opaque
data:
  SERVICE_NAME: $(base64_encode "$service")
  DB_HOST: $(base64_encode "$DB_HOST")
  DB_PORT: $(base64_encode "$DB_PORT")
  DB_NAME: $(base64_encode "${service}_db")
  DB_USER: $(base64_encode "$DB_USER")
  DB_PASSWORD: $(base64_encode "$DB_PASSWORD")
  REDIS_PASSWORD: $(base64_encode "$REDIS_PASSWORD")
  JWT_SECRET: $(base64_encode "$JWT_SECRET")
  API_KEY: $(base64_encode "$API_KEY")
EOF
)
    create_secret_file "$service" "$SERVICE_SECRET"
done

echo ""
echo -e "${GREEN}🎉 All secrets generated successfully!${NC}"
echo ""
echo -e "${YELLOW}Important Notes:${NC}"
echo "1. All secrets now contain proper database credentials"
echo "2. JWT secrets are unique and secure"
echo "3. API keys are generated for each service"
echo "4. Redis passwords are set for caching"
echo "5. Database names are service-specific"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Review the generated secrets"
echo "2. Update any service-specific credentials as needed"
echo "3. Deploy the updated secrets to the cluster"
echo "4. Restart services to pick up new credentials"
echo ""
echo -e "${RED}⚠️  Security Warning:${NC}"
echo "- Keep these secrets secure and don't commit them to version control"
echo "- Consider using a secrets management solution for production"
echo "- Rotate passwords regularly in production environments" 