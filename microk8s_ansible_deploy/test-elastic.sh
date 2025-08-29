#!/bin/bash

# Test script for Elastic Stack deployment

echo "Testing Elastic Stack deployment..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed or not in PATH"
    exit 1
fi

# Check cluster connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo "Error: Not connected to a Kubernetes cluster"
    exit 1
fi

echo "✓ Connected to cluster: $(kubectl config current-context)"

# Deploy Elastic Stack
echo "Deploying Elastic Stack..."
kubectl apply -f elastic-stack.yml

# Wait for Elasticsearch
echo "Waiting for Elasticsearch to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment/elasticsearch

# Wait for Kibana
echo "Waiting for Kibana to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/kibana

# Check status
echo ""
echo "Elastic Stack Status:"
kubectl get pods -l app=elasticsearch
kubectl get pods -l app=kibana
kubectl get services -l app=elasticsearch
kubectl get services -l app=kibana

# Test Elasticsearch connectivity
echo ""
echo "Testing Elasticsearch connectivity..."
ELASTICSEARCH_POD=$(kubectl get pods -l app=elasticsearch -o jsonpath='{.items[0].metadata.name}')
kubectl exec $ELASTICSEARCH_POD -- curl -s http://localhost:9200/_cluster/health | jq . || echo "Elasticsearch health check failed"

echo ""
echo "✓ Elastic Stack deployment test completed!"
echo ""
echo "Access Elasticsearch: kubectl port-forward service/elasticsearch 9200:9200"
echo "Access Kibana: kubectl port-forward service/kibana 5601:5601" 