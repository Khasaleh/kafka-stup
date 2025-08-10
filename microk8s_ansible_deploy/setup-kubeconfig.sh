#!/bin/bash

# Setup kubeconfig for local kubectl access
export KUBECONFIG="$(pwd)/kubeconfig"
echo "KUBECONFIG set to: $KUBECONFIG"
echo "You can now use kubectl commands to access the remote MicroK8s cluster"
echo "Example: kubectl get nodes"
