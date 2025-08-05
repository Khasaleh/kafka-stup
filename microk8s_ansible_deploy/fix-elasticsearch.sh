#!/bin/bash

# Fix Elasticsearch Deployment Script
# This script cleans up the failed Elasticsearch deployment and deploys a fixed version

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

echo -e "${BLUE}🔧 FIXING ELASTICSEARCH DEPLOYMENT${NC}"
echo "=========================================="
echo "Host: $REMOTE_HOST"
echo "User: $REMOTE_USER"
echo "=========================================="
echo ""

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

# Function to clean up failed Elasticsearch deployment
cleanup_elasticsearch() {
    echo -e "${BLUE}🧹 CLEANING UP FAILED ELASTICSEARCH DEPLOYMENT${NC}"
    echo "=========================================="
    
    run_remote_command "kubectl delete statefulset elasticsearch-master -n elasticsearch --ignore-not-found=true"
    run_remote_command "kubectl delete deployment elasticsearch-master -n elasticsearch --ignore-not-found=true"
    run_remote_command "kubectl delete deployment kibana -n elasticsearch --ignore-not-found=true"
    run_remote_command "kubectl delete service elasticsearch-master -n elasticsearch --ignore-not-found=true"
    run_remote_command "kubectl delete service elasticsearch-master-headless -n elasticsearch --ignore-not-found=true"
    run_remote_command "kubectl delete service kibana -n elasticsearch --ignore-not-found=true"
    run_remote_command "kubectl delete pvc --all -n elasticsearch --ignore-not-found=true"
    run_remote_command "kubectl delete pv --all --ignore-not-found=true"
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Function to wait for cleanup
wait_for_cleanup() {
    echo -e "${BLUE}⏳ WAITING FOR CLEANUP${NC}"
    echo "=========================================="
    
    run_remote_command "kubectl get pods -n elasticsearch"
    run_remote_command "kubectl get pvc -n elasticsearch"
    run_remote_command "kubectl get pv"
    
    echo -e "${GREEN}✅ Cleanup verification completed${NC}"
}

# Function to copy fixed deployment files
copy_fixed_files() {
    echo -e "${BLUE}📁 COPYING FIXED DEPLOYMENT FILES${NC}"
    echo "=========================================="
    
    # Create the fixed deployment file on remote
    run_remote_command "cat > /tmp/deploy-elastic-stack-fixed-yaml.yml << 'EOF'
---
- name: Deploy Elastic Stack using YAML manifests (Fixed)
  hosts: localhost
  gather_facts: no

  tasks:
    - name: Create Elasticsearch namespace
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: Namespace
          metadata:
            name: elasticsearch

    - name: Create Storage Class for hostpath
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: storage.k8s.io/v1
          kind: StorageClass
          metadata:
            name: hostpath
            annotations:
              storageclass.kubernetes.io/is-default-class: \"true\"
          provisioner: microk8s.io/hostpath
          reclaimPolicy: Delete
          volumeBindingMode: Immediate

    - name: Deploy Elasticsearch Deployment (instead of StatefulSet)
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: elasticsearch-master
            namespace: elasticsearch
          spec:
            replicas: 1
            selector:
              matchLabels:
                app: elasticsearch-master
            template:
              metadata:
                labels:
                  app: elasticsearch-master
              spec:
                containers:
                - name: elasticsearch
                  image: docker.elastic.co/elasticsearch/elasticsearch:8.5.1
                  ports:
                  - containerPort: 9200
                    name: http
                  - containerPort: 9300
                    name: transport
                  env:
                  - name: cluster.name
                    value: \"elasticsearch\"
                  - name: node.name
                    value: \"elasticsearch-master\"
                  - name: discovery.type
                    value: \"single-node\"
                  - name: ES_JAVA_OPTS
                    value: \"-Xms512m -Xmx512m\"
                  - name: xpack.security.enabled
                    value: \"false\"
                  - name: xpack.security.http.ssl.enabled
                    value: \"false\"
                  - name: xpack.security.transport.ssl.enabled
                    value: \"false\"
                  resources:
                    requests:
                      memory: \"1Gi\"
                      cpu: \"500m\"
                    limits:
                      memory: \"2Gi\"
                      cpu: \"1000m\"
                  readinessProbe:
                    httpGet:
                      path: /_cluster/health
                      port: 9200
                    initialDelaySeconds: 30
                    periodSeconds: 10
                    timeoutSeconds: 5
                    failureThreshold: 3
                  livenessProbe:
                    httpGet:
                      path: /_cluster/health
                      port: 9200
                    initialDelaySeconds: 60
                    periodSeconds: 30
                    timeoutSeconds: 10
                    failureThreshold: 3

    - name: Deploy Elasticsearch Service
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: Service
          metadata:
            name: elasticsearch-master
            namespace: elasticsearch
          spec:
            ports:
            - port: 9200
              targetPort: 9200
              name: http
            - port: 9300
              targetPort: 9300
              name: transport
            selector:
              app: elasticsearch-master

    - name: Deploy Kibana Deployment
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: kibana
            namespace: elasticsearch
          spec:
            replicas: 1
            selector:
              matchLabels:
                app: kibana
            template:
              metadata:
                labels:
                  app: kibana
              spec:
                containers:
                - name: kibana
                  image: docker.elastic.co/kibana/kibana:8.5.1
                  ports:
                  - containerPort: 5601
                    name: http
                  env:
                  - name: ELASTICSEARCH_HOSTS
                    value: \"http://elasticsearch-master:9200\"
                  - name: SERVER_NAME
                    value: \"kibana\"
                  - name: SERVER_HOST
                    value: \"0.0.0.0\"
                  - name: ELASTICSEARCH_SSL_VERIFY
                    value: \"false\"
                  resources:
                    requests:
                      memory: \"512Mi\"
                      cpu: \"250m\"
                    limits:
                      memory: \"1Gi\"
                      cpu: \"500m\"
                  readinessProbe:
                    httpGet:
                      path: /api/status
                      port: 5601
                    initialDelaySeconds: 30
                    periodSeconds: 10
                    timeoutSeconds: 5
                    failureThreshold: 3
                  livenessProbe:
                    httpGet:
                      path: /api/status
                      port: 5601
                    initialDelaySeconds: 60
                    periodSeconds: 30
                    timeoutSeconds: 10
                    failureThreshold: 3

    - name: Deploy Kibana Service
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: Service
          metadata:
            name: kibana
            namespace: elasticsearch
          spec:
            ports:
            - port: 5601
              targetPort: 5601
              name: http
            selector:
              app: kibana

    - name: Wait for Elasticsearch to be ready
      kubernetes.core.k8s_info:
        kind: Pod
        namespace: elasticsearch
        label_selectors:
          - app=elasticsearch-master
      register: elasticsearch_pods
      until: elasticsearch_pods.resources | length > 0 and elasticsearch_pods.resources[0].status.phase == 'Running'
      retries: 30
      delay: 10

    - name: Wait for Kibana to be ready
      kubernetes.core.k8s_info:
        kind: Pod
        namespace: elasticsearch
        label_selectors:
          - app=kibana
      register: kibana_pods
      until: kibana_pods.resources | length > 0 and kibana_pods.resources[0].status.phase == 'Running'
      retries: 30
      delay: 10

    - name: Display deployment status
      debug:
        msg: \"Elastic Stack deployment completed successfully\"
EOF"
    
    echo -e "${GREEN}✅ Fixed deployment file created${NC}"
}

# Function to deploy fixed Elasticsearch
deploy_fixed_elasticsearch() {
    echo -e "${BLUE}🚀 DEPLOYING FIXED ELASTICSEARCH${NC}"
    echo "=========================================="
    
    run_remote_command "cd /tmp && ansible-playbook -i localhost, deploy-elastic-stack-fixed-yaml.yml --connection=local"
    
    echo -e "${GREEN}✅ Fixed deployment completed${NC}"
}

# Function to verify deployment
verify_deployment() {
    echo -e "${BLUE}🔍 VERIFYING DEPLOYMENT${NC}"
    echo "=========================================="
    
    run_remote_command "kubectl get pods -n elasticsearch"
    run_remote_command "kubectl get services -n elasticsearch"
    run_remote_command "kubectl get storageclass"
    run_remote_command "kubectl describe pods -n elasticsearch"
    
    echo -e "${GREEN}✅ Verification completed${NC}"
}

# Main execution
main() {
    echo -e "${BLUE}Starting Elasticsearch fix process...${NC}"
    echo ""
    
    # Clean up failed deployment
    cleanup_elasticsearch
    
    # Wait for cleanup
    wait_for_cleanup
    
    # Copy fixed files
    copy_fixed_files
    
    # Deploy fixed version
    deploy_fixed_elasticsearch
    
    # Verify deployment
    verify_deployment
    
    echo -e "${GREEN}🎉 Elasticsearch fix completed!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Check if Elasticsearch pods are running: kubectl get pods -n elasticsearch"
    echo "2. Check if Kibana is accessible: kubectl port-forward -n elasticsearch svc/kibana 5601:5601"
    echo "3. Check Elasticsearch health: kubectl port-forward -n elasticsearch svc/elasticsearch-master 9200:9200"
    echo ""
}

# Check if sshpass is available
if ! command -v sshpass &> /dev/null; then
    echo -e "${RED}Error: sshpass is not installed${NC}"
    echo -e "${YELLOW}Please install sshpass:${NC}"
    echo "  macOS: brew install sshpass"
    echo "  Ubuntu: sudo apt-get install sshpass"
    echo "  CentOS: sudo yum install sshpass"
    exit 1
fi

# Run main function
main 