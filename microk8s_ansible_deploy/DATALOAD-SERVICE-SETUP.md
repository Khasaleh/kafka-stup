# Dataload Service Setup

## Overview

The dataload service is a FastAPI application with Celery worker for handling data uploads and processing. It includes persistent storage for file uploads and is integrated into the full deployment pipeline.

## Components

### 1. FastAPI Application
- **Service Name**: `dataload-service`
- **Port**: 8000
- **Image**: `khsaleh889/familymicroservices:${IMAGE_TAG}`
- **Resources**: 256Mi-512Mi memory, 250m-500m CPU

### 2. Celery Worker
- **Service Name**: `dataload-service-celery-worker`
- **Image**: `khsaleh889/familymicroservices:${IMAGE_TAG}`
- **Command**: `celery -A app.tasks.celery_worker.celery_app worker -l INFO`
- **Resources**: 512Mi-1Gi memory, 500m-1 CPU

### 3. Persistent Storage
- **Volume Name**: `uploads-storage`
- **Capacity**: 5Gi
- **Access Mode**: ReadWriteMany
- **Mount Path**: `/data/uploads`
- **Host Path**: `/data/uploads`

## Kubernetes Resources

### Files Created

1. **`dataload-service.yml`** - Complete service definition
2. **`application_deployment/dev/dataload-service/`** - Individual deployment files:
   - `deployment.yml` - FastAPI and Celery deployments
   - `service.yml` - ClusterIP service
   - `configmap.yml` - Configuration data
   - `secret.yml` - Secret data
   - `pv-pvc.yml` - Persistent volume and claim

### Resource Structure

```
dataload-service/
├── deployment.yml      # FastAPI + Celery deployments
├── service.yml         # ClusterIP service
├── configmap.yml       # Configuration
├── secret.yml          # Secrets
└── pv-pvc.yml         # Persistent storage
```

## Configuration

### Environment Variables

```yaml
env:
  - name: DISCOVERY_URL
    value: "http://192.168.1.212:8761"
  - name: SPRING_PROFILES_ACTIVE
    value: "dev"
  - name: CONFIG_URL
    value: "http://config-server"
```

### ConfigMap Data

```yaml
data:
  LOG_LEVEL: "INFO"
  ENVIRONMENT: "dev"
```

### Persistent Storage

```yaml
volumes:
  - name: uploads-storage
    persistentVolumeClaim:
      claimName: uploads-pvc

volumeMounts:
  - name: uploads-storage
    mountPath: /data/uploads
```

## Health Checks

### Readiness Probe
```yaml
readinessProbe:
  httpGet:
    path: /
    port: 8000
  initialDelaySeconds: 20
  periodSeconds: 25
  timeoutSeconds: 5
  failureThreshold: 3
```

### Liveness Probe
```yaml
livenessProbe:
  httpGet:
    path: /
    port: 8000
  initialDelaySeconds: 40
  periodSeconds: 30
  timeoutSeconds: 5
  failureThreshold: 3
```

## Integration

### Deployment Script
The dataload service is included in the `deploy_business_services()` function and will be deployed as part of the full application deployment.

### Jenkins Integration
The service is included in the Jenkins trigger script:
- **Job Name**: `multi-branch-k8s-dev-dataload-service`
- **Trigger**: Part of application builds

## Usage

### Manual Deployment
```bash
# Deploy persistent storage
kubectl apply -f application_deployment/dev/dataload-service/pv-pvc.yml

# Deploy configuration
kubectl apply -f application_deployment/dev/dataload-service/configmap.yml
kubectl apply -f application_deployment/dev/dataload-service/secret.yml

# Deploy service
kubectl apply -f application_deployment/dev/dataload-service/service.yml

# Deploy applications
kubectl apply -f application_deployment/dev/dataload-service/deployment.yml
```

### Full Pipeline Deployment
```bash
# Deploy with Jenkins triggering
./deploy-full-applications.sh dev v1.2.3 default true http://192.168.1.224:8080 khaled Welcome123 ""

# Deploy without Jenkins
./deploy-full-applications.sh dev v1.2.3 default false
```

### Jenkins Build Trigger
```bash
# Trigger dataload service build specifically
./jenkins-trigger.sh applications http://192.168.1.224:8080 khaled Welcome123 "" dev latest
```

## Monitoring

### Service Status
```bash
# Check service status
kubectl get pods -l app=dataload-service

# Check service endpoints
kubectl get svc dataload-service

# Check persistent volumes
kubectl get pv,pvc | grep uploads
```

### Logs
```bash
# FastAPI logs
kubectl logs -l app=dataload-service,component=fastapi

# Celery worker logs
kubectl logs -l app=dataload-service,component=celery-worker
```

## Storage Setup

### Host Directory
Ensure the host directory exists:
```bash
# Create uploads directory on host
sudo mkdir -p /data/uploads
sudo chmod 755 /data/uploads
```

### Volume Verification
```bash
# Check volume status
kubectl get pv uploads-pv
kubectl get pvc uploads-pvc

# Check volume details
kubectl describe pv uploads-pv
kubectl describe pvc uploads-pvc
```

## Troubleshooting

### Common Issues

1. **Volume Mount Failures**
   - Verify host directory exists: `/data/uploads`
   - Check volume permissions
   - Ensure PVC is bound to PV

2. **Service Startup Issues**
   - Check resource limits
   - Verify image exists: `khsaleh889/familymicroservices:${IMAGE_TAG}`
   - Check health probe configuration

3. **Celery Worker Issues**
   - Verify Redis/Celery broker configuration
   - Check worker logs for task processing errors
   - Ensure proper environment variables

### Debug Commands
```bash
# Check pod events
kubectl describe pod -l app=dataload-service

# Check service endpoints
kubectl get endpoints dataload-service

# Check volume mounts
kubectl exec -it <pod-name> -- df -h /data/uploads
```

## Security Considerations

1. **Secrets Management**
   - Store sensitive data in Kubernetes secrets
   - Use base64 encoding for secret values
   - Rotate secrets regularly

2. **Volume Security**
   - Restrict access to `/data/uploads` directory
   - Use appropriate file permissions
   - Consider encryption for sensitive data

3. **Network Security**
   - Use ClusterIP service type for internal access
   - Configure network policies if needed
   - Secure communication with external services

---

**Status**: ✅ Ready for Deployment
**Version**: 1.0
**Last Updated**: $(date) 