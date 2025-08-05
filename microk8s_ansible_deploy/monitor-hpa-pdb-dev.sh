#!/bin/bash

# Monitor HPA and PDB Script
# This script provides monitoring commands for HPA and PDB

set -e

ENV=${1:-dev}
NAMESPACE=${2:-default}

echo "HPA and PDB Monitoring Commands for $ENV environment"
echo "=================================================="
echo ""

echo "1. Check HPA Status:"
echo "   kubectl get hpa -n $NAMESPACE"
echo ""

echo "2. Check PDB Status:"
echo "   kubectl get pdb -n $NAMESPACE"
echo ""

echo "3. Check Pod Distribution:"
echo "   kubectl get pods -n $NAMESPACE -o wide"
echo ""

echo "4. Check Resource Usage:"
echo "   kubectl top pods -n $NAMESPACE"
echo ""

echo "5. Check Node Resource Usage:"
echo "   kubectl top nodes"
echo ""

echo "6. Detailed HPA Information:"
echo "   kubectl describe hpa -n $NAMESPACE"
echo ""

echo "7. Detailed PDB Information:"
echo "   kubectl describe pdb -n $NAMESPACE"
echo ""

echo "8. Check Scaling Events:"
echo "   kubectl get events -n $NAMESPACE --sort-by='.lastTimestamp' | grep -i hpa"
echo ""
