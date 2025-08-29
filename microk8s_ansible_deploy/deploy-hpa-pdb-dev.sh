#!/bin/bash

# Deploy HPA and PDB Script
# This script deploys all HPA and PDB configurations

set -e

ENV=${1:-dev}
NAMESPACE=${2:-default}

echo "Deploying HPA and PDB configurations for $ENV environment..."

# Deploy PDBs first (they need to exist before scaling)
echo "Deploying Pod Disruption Budgets..."
for service in application_deployment/$ENV/*; do
    if [ -d "$service" ] && [ -f "$service/pdb.yml" ]; then
        echo "  - Deploying PDB for $(basename $service)..."
        kubectl apply -f "$service/pdb.yml" -n $NAMESPACE
    fi
done

# Deploy HPAs
echo "Deploying Horizontal Pod Autoscalers..."
for service in application_deployment/$ENV/*; do
    if [ -d "$service" ] && [ -f "$service/hpa.yml" ]; then
        echo "  - Deploying HPA for $(basename $service)..."
        kubectl apply -f "$service/hpa.yml" -n $NAMESPACE
    fi
done

echo "HPA and PDB deployment completed!"
echo ""
echo "To monitor HPA status:"
echo "  kubectl get hpa -n $NAMESPACE"
echo ""
echo "To monitor PDB status:"
echo "  kubectl get pdb -n $NAMESPACE"
