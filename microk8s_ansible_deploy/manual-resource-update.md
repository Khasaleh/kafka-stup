# Manual Resource Allocation Update Guide

## Overview
This guide provides the exact resource configurations to manually update each service based on their usage category.

## Service Categories

### High Usage Services
These services require more resources due to high traffic and processing demands:

- **Angular Services** (Frontend applications)
- **api-server** (Main API gateway)
- **fazeal-business** (Business management)
- **order-service** (Order processing)
- **catalog-service** (Product catalog)
- **posts-service** (Content management)
- **promotion-service** (Promotional activities)
- **customer-service** (Customer management)

### Medium Usage Services
These services have moderate traffic and processing needs:

- **payment-service** (Payment processing)
- **notification-service** (Notifications)
- **loyalty-service** (Loyalty programs)
- **inventory-service** (Inventory management)
- **events-service** (Event processing)
- **chat-app** (Chat functionality)
- **business-chat** (Business chat)
- **album-service** (Media management)
- **translation-service** (Translation services)
- **watermark-detection** (Image processing)
- **site-management-service** (Site administration)
- **shopping-service** (Shopping cart)
- **payment-gateway** (Payment routing)
- **employees-service** (Employee management)
- **ads-service** (Advertisement service)

### Low Usage Services
These services have minimal traffic and resource requirements:

- **config-server** (Configuration management)
- **api-gateway** (API routing)
- **cron-jobs** (Scheduled tasks)
- **dataload-service** (Data loading)
- **search-service** (Search functionality)
- **fazeal-logistics** (Logistics management)

## Resource Configurations

### High Usage Services Configuration
Replace the existing resources section in each high-usage service with:

```yaml
          resources:
            requests:
              memory: "1Gi"
              cpu: "500m"
            limits:
              memory: "2Gi"
              cpu: "1000m"
          livenessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 60
            periodSeconds: 30
            timeoutSeconds: 10
            failureThreshold: 3
          readinessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
            successThreshold: 1
```

### Medium Usage Services Configuration
Replace the existing resources section in each medium-usage service with:

```yaml
          resources:
            requests:
              memory: "512Mi"
              cpu: "250m"
            limits:
              memory: "1Gi"
              cpu: "500m"
          livenessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 45
            periodSeconds: 30
            timeoutSeconds: 10
            failureThreshold: 3
          readinessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 20
            periodSeconds: 15
            timeoutSeconds: 5
            failureThreshold: 3
            successThreshold: 1
```

### Low Usage Services Configuration
Replace the existing resources section in each low-usage service with:

```yaml
          resources:
            requests:
              memory: "256Mi"
              cpu: "100m"
            limits:
              memory: "512Mi"
              cpu: "250m"
          livenessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 30
            periodSeconds: 30
            timeoutSeconds: 10
            failureThreshold: 3
          readinessProbe:
            tcpSocket:
              port: 80
            initialDelaySeconds: 15
            periodSeconds: 20
            timeoutSeconds: 5
            failureThreshold: 3
            successThreshold: 1
```

## Update Instructions

### Step 1: Backup Current Configuration
```bash
# Create backup of all deployment files
for service in application_deployment/dev/*; do
    if [ -d "$service" ]; then
        cp "$service/deployment.yml" "$service/deployment.yml.backup"
    fi
done
```

### Step 2: Update High Usage Services
Update these services first:
- angular-dev
- angular-customer
- angular-business
- angular-ads
- angular-employee
- angular-customer-ssr
- api-server
- fazeal-business
- order-service
- catalog-service
- posts-service
- promotion-service
- customer-service

### Step 3: Update Medium Usage Services
Update these services:
- payment-service
- notification-service
- loyalty-service
- inventory-service
- events-service
- chat-app
- business-chat
- album-service
- translation-service
- watermark-detection
- site-management-service
- shopping-service
- payment-gateway
- employees-service
- ads-service

### Step 4: Update Low Usage Services
Update these services:
- config-server
- api-gateway
- cron-jobs
- dataload-service
- search-service
- fazeal-logistics

## Verification

### Check Resource Allocation
```bash
# Verify resources are set correctly
grep -A 10 "resources:" application_deployment/dev/*/deployment.yml
```

### Check Health Probes
```bash
# Verify health probes are configured
grep -A 10 "readinessProbe:" application_deployment/dev/*/deployment.yml
grep -A 10 "livenessProbe:" application_deployment/dev/*/deployment.yml
```

## Special Considerations

### Angular Services
- Higher memory requirements for UI rendering
- Lower CPU requirements
- Longer initial delay for build processes

### API Server
- High CPU for request processing
- Moderate memory for request handling
- Aggressive health checks

### Database-Heavy Services
- Higher memory for connection pools
- Moderate CPU for query processing
- Longer initial delays for database connections

### Background Processing Services
- Higher CPU for processing tasks
- Moderate memory for task queues
- Less aggressive health checks

## Rollback Instructions

If you need to rollback the changes:

```bash
# Restore from backup
for service in application_deployment/dev/*; do
    if [ -d "$service" ]; then
        cp "$service/deployment.yml.backup" "$service/deployment.yml"
    fi
done
```

## Monitoring

After updating resources, monitor:

1. **Pod Resource Usage**: Check actual CPU and memory consumption
2. **Pod Restarts**: Monitor for any issues with new health probe settings
3. **Service Performance**: Ensure services are responding correctly
4. **Node Resource Pressure**: Check if nodes have sufficient resources

## Next Steps

1. **Deploy and Test**: Deploy the updated configurations
2. **Monitor Performance**: Watch resource usage and service health
3. **Adjust as Needed**: Fine-tune based on actual usage patterns
4. **Set up HPA**: Consider Horizontal Pod Autoscaling for high-usage services 