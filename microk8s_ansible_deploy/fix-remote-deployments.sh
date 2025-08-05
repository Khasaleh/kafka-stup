#!/bin/bash

# Fix Remote Deployments Script
# This script creates proper deployment files on the remote server

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

REMOTE_HOST="192.168.1.225"
REMOTE_USER="root"
REMOTE_PASS="Infotec1212!@"
REMOTE_DIR="/root/microk8s_ansible_deploy"

echo -e "${BLUE}🔧 FIXING REMOTE DEPLOYMENTS${NC}"
echo "=========================================="
echo "Host: $REMOTE_HOST"
echo "User: $REMOTE_USER"
echo "Remote Directory: $REMOTE_DIR"
echo "=========================================="

# Function to run remote command
run_remote_command() {
    local command="$1"
    echo -e "${YELLOW}Running: $command${NC}"
    echo "----------------------------------------"
    
    sshpass -p "$REMOTE_PASS" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$REMOTE_USER@$REMOTE_HOST" "$command"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Command completed successfully${NC}"
    else
        echo -e "${RED}❌ Command failed${NC}"
    fi
    echo ""
}

# Create config-server deployment
echo -e "${BLUE}Creating config-server deployment...${NC}"
run_remote_command "cd $REMOTE_DIR && cat > application_deployment/dev/config-server/deployment.yml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: config-server
  namespace: default
  labels:
    app: config-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: config-server
  template:
    metadata:
      labels:
        app: config-server
    spec:
      imagePullSecrets:
        - name: dockerhub-secret
      containers:
        - name: config-server
          image: khsaleh889/config-server:v1.2.3
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 8761
              name: http
          env:
            - name: SERVICE_NAME
              value: 'config-server'
            - name: NAMESPACE
              value: 'default'
            - name: PORT
              value: '8761'
            - name: SPRING_PROFILES_ACTIVE
              value: 'dev'
          envFrom:
            - configMapRef:
                name: config-server-config
            - secretRef:
                name: config-server-secret
          resources:
            requests:
              memory: '512Mi'
              cpu: '250m'
            limits:
              memory: '1Gi'
              cpu: '500m'
          livenessProbe:
            httpGet:
              path: /actuator/health
              port: 8761
            initialDelaySeconds: 60
            periodSeconds: 30
            timeoutSeconds: 10
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: 8761
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
EOF"

# Create config-server secret
echo -e "${BLUE}Creating config-server secret...${NC}"
run_remote_command "cd $REMOTE_DIR && cat > application_deployment/dev/config-server/secret.yml << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: config-server-secret
  namespace: default
  labels:
    app: config-server
type: Opaque
data:
  SERVICE_NAME: Y29uZmlnLXNlcnZlcg==
  DB_HOST: MTkyLjE2OC4xLjIyNA==
  DB_PORT: NTQzMg==
  DB_NAME: Y29uZmlnLXNlcnZlcl9kYg==
  DB_USER: YWRtaW4=
  DB_PASSWORD: bmV3MjAyNQ==
  REDIS_PASSWORD: YWRtaW4xMjM0
  JWT_SECRET: and0X3NlY3JldF9rZXlfZm9yX2NvbmZpZy1zZXJ2ZXJfMjAyNA==
  API_KEY: YXBpX2tleV9jb25maWctc2VydmVyXzIwMjQ=
EOF"

# Create config-server configmap
echo -e "${BLUE}Creating config-server configmap...${NC}"
run_remote_command "cd $REMOTE_DIR && cat > application_deployment/dev/config-server/configmap.yml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-server-config
  namespace: default
  labels:
    app: config-server
data:
  SERVICE_NAME: 'config-server'
  NAMESPACE: 'default'
  ENVIRONMENT: 'dev'
  LOG_LEVEL: 'INFO'
EOF"

# Test the deployment
echo -e "${BLUE}Testing config-server deployment...${NC}"
run_remote_command "cd $REMOTE_DIR && kubectl apply -f application_deployment/dev/config-server/deployment.yml"

# Check the deployment
run_remote_command "kubectl get deployment config-server -n default"

echo -e "${GREEN}🎉 Remote deployments fixed!${NC}" 