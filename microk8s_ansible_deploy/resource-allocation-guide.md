# Resource Allocation Guide

## Service Categories

### High Usage Services
These services require more resources due to high traffic and processing demands:

- **Angular Services** (Frontend applications)
- **api-server** (Main API gateway)
- **fazeal-business** (Business management)
- **order-management** (Order processing)
- **catalog-management** (Product catalog)
- **post-service** (Content management)
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

## Resource Allocation Strategy

### High Usage Services
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"
```

### Medium Usage Services
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "250m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

### Low Usage Services
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"
    cpu: "250m"
```

## Readiness Probe Configuration

### High Usage Services
```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
  successThreshold: 1
```

### Medium Usage Services
```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 20
  periodSeconds: 15
  timeoutSeconds: 5
  failureThreshold: 3
  successThreshold: 1
```

### Low Usage Services
```yaml
readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 20
  timeoutSeconds: 5
  failureThreshold: 3
  successThreshold: 1
```

## Liveness Probe Configuration

### High Usage Services
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 60
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 3
```

### Medium Usage Services
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 45
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 3
```

### Low Usage Services
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 3
```

## Special Considerations

### Angular Services (Frontend)
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

## Implementation Notes

1. **Health Endpoints**: Ensure all services have `/health` endpoints
2. **Resource Monitoring**: Monitor actual usage and adjust accordingly
3. **Horizontal Pod Autoscaling**: Consider HPA for high-usage services
4. **Node Affinity**: Consider node affinity for resource-intensive services
5. **Pod Disruption Budgets**: Implement PDBs for critical services 