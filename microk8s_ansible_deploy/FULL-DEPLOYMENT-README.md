# Full Deployment Script for MicroK8s Cluster

This comprehensive deployment script handles the complete deployment of your microservices application including Elastic Stack, Ingress Controller, and all services.

## Features

- ✅ **Complete Cleanup**: Removes old deployments before new deployment
- ✅ **Elastic Stack**: Deploys Elasticsearch and Kibana using Helm
- ✅ **Ingress Controller**: Deploys NGINX Ingress Controller
- ✅ **Environment-Specific Ingress**: Creates ingress rules for all services
- ✅ **All Services**: Deploys all 32 microservices
- ✅ **Docker Hub Integration**: Handles Docker Hub authentication
- ✅ **Status Monitoring**: Shows deployment status and access URLs

## Prerequisites

1. **Kubernetes Cluster**: MicroK8s cluster running
2. **kubectl**: Configured and connected to your cluster
3. **Helm**: Installed and configured
4. **Docker Hub Credentials**: Valid Docker Hub account

## Configuration

### 1. Update Docker Hub Credentials

Edit `docker-config.env` with your actual Docker Hub credentials:

```bash
# Update these values
DOCKER_USERNAME=your_username
DOCKER_PASSWORD=your_password
DOCKER_EMAIL=your_email@example.com
```

### 2. Environment Variables

The script accepts the following parameters:

```bash
./full-deployment.sh [ENVIRONMENT] [IMAGE_TAG] [NAMESPACE]
```

- `ENVIRONMENT`: dev, stg, prod (default: dev)
- `IMAGE_TAG`: Docker image tag (default: latest)
- `NAMESPACE`: Kubernetes namespace (default: default)

## Usage

### Basic Usage

```bash
# Deploy to dev environment with latest image
./full-deployment.sh dev

# Deploy to staging with specific image tag
./full-deployment.sh stg v1.2.3

# Deploy to production in custom namespace
./full-deployment.sh prod v1.2.3 production
```

### Step-by-Step Process

The script performs the following steps in order:

1. **Prerequisites Check**: Verifies kubectl and cluster connectivity
2. **Cleanup**: Removes old deployments, services, configmaps, secrets, and ingresses
3. **Docker Hub Secret**: Creates or updates Docker Hub authentication secret
4. **Elastic Stack**: Deploys Elasticsearch and Kibana using Helm
5. **Ingress Controller**: Deploys NGINX Ingress Controller
6. **Ingress Configuration**: Creates environment-specific ingress rules
7. **Services Deployment**: Deploys all 32 microservices
8. **Status Report**: Shows deployment status and access URLs

## Generated Ingress Rules

The script creates ingress rules for the following services:

### Core Services
- `{env}-kube.fazeal.com` → api-gateway
- `{env}-kube-api.fazeal.com` → api-server
- `{env}-config.fazeal.com` → config-server

### Business Services
- `{env}-business-admin.fazeal.com` → fazeal-business-management
- `{env}-business.fazeal.com` → angular-business
- `{env}-customer.fazeal.com` → angular-customer
- `{env}-customer-ssr.fazeal.com` → angular-customer-ssr

### Microservices
- `{env}-kube-post.fazeal.com` → posts-service
- `{env}-kube-customer.fazeal.com` → customer-service
- `{env}-kube-chat.fazeal.com` → chat-app
- `{env}-kube-business-chat.fazeal.com` → business-chat
- `{env}-kube-translation.fazeal.com` → translation-service
- `{env}-kube-ads.fazeal.com` → ads-service
- `{env}-ads.fazeal.com` → angular-ads
- `{env}-kube-cron.fazeal.com` → cron-jobs
- `{env}-promotion.fazeal.com` → promotion-service
- `{env}-kube-logistics.fazeal.com` → fazeal-logistics

### Monitoring & Analytics
- `{env}-elastic.fazeal.com` → elasticsearch
- `{env}-kibana.fazeal.com` → kibana

## Monitoring

### Check Deployment Status

```bash
# Check all pods
kubectl get pods -n default

# Check services
kubectl get services -n default

# Check ingress
kubectl get ingress -n default

# Check Elastic Stack
kubectl get pods -n default | grep -E "(elasticsearch|kibana)"

# Check Ingress Controller
kubectl get pods -n default | grep ingress-nginx
```

### Access Services

After deployment, you can access services through:

- **API Gateway**: `dev-kube.fazeal.com`
- **API Server**: `dev-kube-api.fazeal.com`
- **Kibana**: `dev-kibana.fazeal.com`
- **Elasticsearch**: `dev-elastic.fazeal.com`

## Troubleshooting

### Common Issues

1. **Docker Hub Authentication Failed**
   ```bash
   # Create secret manually
   kubectl create secret docker-registry dockerhub-secret \
     --docker-server=https://index.docker.io/v1/ \
     --docker-username=YOUR_USERNAME \
     --docker-password=YOUR_PASSWORD \
     --docker-email=YOUR_EMAIL \
     -n default
   ```

2. **Helm Repository Issues**
   ```bash
   # Update Helm repositories
   helm repo update
   ```

3. **Pod Startup Issues**
   ```bash
   # Check pod logs
   kubectl logs <pod-name> -n default
   
   # Describe pod for more details
   kubectl describe pod <pod-name> -n default
   ```

4. **Ingress Not Working**
   ```bash
   # Check ingress controller
   kubectl get pods -n default | grep ingress-nginx
   
   # Check ingress status
   kubectl describe ingress dev-ingress -n default
   ```

### Logs and Debugging

```bash
# Get logs from specific service
kubectl logs -f deployment/config-server -n default

# Check events
kubectl get events -n default --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n default
```

## File Structure

```
microk8s_ansible_deploy/
├── full-deployment.sh          # Main deployment script
├── docker-config.env           # Docker Hub configuration
├── application_deployment/     # Service manifests
│   └── dev/
│       ├── config-server/
│       │   ├── deployment.yml
│       │   ├── service.yml
│       │   ├── configmap.yml
│       │   └── secret.yml
│       ├── api-server/
│       └── ... (other services)
│       └── ingress.yml         # Generated ingress configuration
└── FULL-DEPLOYMENT-README.md   # This file
```

## Customization

### Adding New Services

1. Add service to the `services` array in `full-deployment.sh`
2. Create service manifests in `application_deployment/{env}/{service}/`
3. Add ingress rule in the `create_ingress()` function

### Modifying Ingress Rules

Edit the `create_ingress()` function in `full-deployment.sh` to modify:
- Host names
- Service ports
- Path configurations
- Annotations

### Environment-Specific Configurations

Create environment-specific configurations by:
1. Adding environment variables to `docker-config.env`
2. Modifying the script to use environment-specific values
3. Creating environment-specific manifest directories

## Security Considerations

- Store Docker Hub credentials securely
- Use Kubernetes secrets for sensitive data
- Consider using RBAC for production deployments
- Regularly update image tags and dependencies

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review pod logs and events
3. Verify cluster resources and connectivity
4. Ensure all prerequisites are met 