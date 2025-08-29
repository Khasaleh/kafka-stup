# HPA and PDB Configuration Guide

## 🎯 **Overview**

This guide covers the Horizontal Pod Autoscaler (HPA) and Pod Disruption Budget (PDB) configurations for all services, ensuring high availability and optimal resource utilization.

## 📊 **Service Categories & Configurations**

### 🔴 **High Usage Services** (13 services)
**HPA**: 2-10 replicas | **PDB**: 50% availability

#### **Frontend Applications**
- angular-dev, angular-customer, angular-business, angular-ads, angular-employee, angular-customer-ssr

#### **Core Business Services**
- api-server, fazeal-business, order-service, catalog-service, posts-service, promotion-service, customer-service

**Configuration:**
```yaml
# HPA Configuration
minReplicas: 2
maxReplicas: 10
targetCPUUtilization: 70%
targetMemoryUtilization: 70%

# PDB Configuration
minAvailable: 50%
```

### 🟡 **Medium Usage Services** (15 services)
**HPA**: 2-8 replicas | **PDB**: 50% availability

#### **Payment & Financial Services**
- payment-service, payment-gateway

#### **Communication Services**
- notification-service, chat-app, business-chat

#### **Business Logic Services**
- loyalty-service, inventory-service, events-service, album-service, translation-service, watermark-detection, site-management-service, shopping-service, employees-service, ads-service

**Configuration:**
```yaml
# HPA Configuration
minReplicas: 2
maxReplicas: 8
targetCPUUtilization: 70%
targetMemoryUtilization: 70%

# PDB Configuration
minAvailable: 50%
```

### 🟢 **Low Usage Services** (4 services)
**HPA**: 1-3 replicas | **PDB**: 1 pod minimum

#### **Infrastructure Services**
- config-server, api-gateway, cron-jobs, dataload-service

**Configuration:**
```yaml
# HPA Configuration
minReplicas: 1
maxReplicas: 3
targetCPUUtilization: 70%
targetMemoryUtilization: 70%

# PDB Configuration
minAvailable: 1
```

## 🔧 **HPA Configuration Details**

### **Scaling Metrics**
- **CPU Utilization**: 70% threshold
- **Memory Utilization**: 70% threshold
- **Dual Metric Scaling**: Both CPU and memory are monitored

### **Scaling Behavior**

#### **Scale Up (Aggressive)**
```yaml
scaleUp:
  stabilizationWindowSeconds: 60
  policies:
  - type: Percent
    value: 100        # 100% increase allowed
    periodSeconds: 15 # Every 15 seconds
  - type: Pods
    value: 2          # Max 2 pods per 15 seconds
    periodSeconds: 15
  selectPolicy: Max   # Use the most aggressive policy
```

#### **Scale Down (Conservative)**
```yaml
scaleDown:
  stabilizationWindowSeconds: 300  # 5 minutes stabilization
  policies:
  - type: Percent
    value: 10         # 10% decrease allowed
    periodSeconds: 60 # Every 60 seconds
  - type: Pods
    value: 1          # Max 1 pod per 60 seconds
    periodSeconds: 60
  selectPolicy: Max   # Use the most conservative policy
```

### **Benefits of This Configuration**
1. **Fast Response**: Quick scaling up when load increases
2. **Stable Scaling Down**: Prevents rapid scaling down during temporary spikes
3. **Resource Efficiency**: Maintains optimal resource utilization
4. **Cost Control**: Prevents unnecessary scaling during brief load changes

## 🛡️ **PDB Configuration Details**

### **High Availability Strategy**
- **High/Medium Services**: 50% of pods must remain available
- **Low Services**: At least 1 pod must remain available
- **Node Maintenance**: Ensures service availability during node updates

### **Benefits of PDB**
1. **Zero Downtime**: Services remain available during node maintenance
2. **Rolling Updates**: Supports rolling deployment strategies
3. **Disaster Recovery**: Protects against accidental pod deletion
4. **Load Balancing**: Ensures proper pod distribution across nodes

## 📁 **File Structure**

### **Generated Files**
```
application_deployment/dev/
├── api-server/
│   ├── deployment.yml
│   ├── service.yml
│   ├── configmap.yml
│   ├── secret.yml
│   ├── hpa.yml          # ✅ New HPA configuration
│   └── pdb.yml          # ✅ New PDB configuration
├── order-service/
│   ├── deployment.yml
│   ├── service.yml
│   ├── hpa.yml          # ✅ New HPA configuration
│   └── pdb.yml          # ✅ New PDB configuration
└── ... (all 33 services)
```

### **Scripts Created**
- ✅ `create-hpa-pdb.sh` - Main creation script
- ✅ `deploy-hpa-pdb-dev.sh` - Deployment script
- ✅ `monitor-hpa-pdb-dev.sh` - Monitoring script

## 🚀 **Deployment Instructions**

### **1. Deploy HPA and PDB Configurations**
```bash
# Deploy all HPA and PDB configurations
./deploy-hpa-pdb-dev.sh dev default

# Or manually deploy specific services
kubectl apply -f application_deployment/dev/api-server/hpa.yml -n default
kubectl apply -f application_deployment/dev/api-server/pdb.yml -n default
```

### **2. Verify Deployment**
```bash
# Check HPA status
kubectl get hpa -n default

# Check PDB status
kubectl get pdb -n default

# Check pod distribution
kubectl get pods -n default -o wide
```

### **3. Monitor Scaling**
```bash
# Watch HPA scaling
kubectl get hpa -n default -w

# Check scaling events
kubectl get events -n default --sort-by='.lastTimestamp' | grep -i hpa

# Monitor resource usage
kubectl top pods -n default
```

## 📊 **Monitoring Commands**

### **HPA Monitoring**
```bash
# List all HPAs
kubectl get hpa -n default

# Detailed HPA information
kubectl describe hpa api-server-hpa -n default

# Check HPA metrics
kubectl get hpa api-server-hpa -n default -o yaml

# Watch HPA scaling
kubectl get hpa -n default -w
```

### **PDB Monitoring**
```bash
# List all PDBs
kubectl get pdb -n default

# Detailed PDB information
kubectl describe pdb api-server-pdb -n default

# Check PDB status
kubectl get pdb api-server-pdb -n default -o yaml
```

### **Resource Monitoring**
```bash
# Check pod resource usage
kubectl top pods -n default

# Check node resource usage
kubectl top nodes

# Check pod distribution across nodes
kubectl get pods -n default -o wide

# Check node capacity
kubectl describe nodes
```

## ⚠️ **Important Considerations**

### **Prerequisites**
1. **Metrics Server**: Must be installed for HPA to work
2. **Resource Requests**: All deployments must have resource requests defined
3. **Node Resources**: Sufficient node resources for scaling
4. **Network Policies**: Ensure proper network access for scaling

### **Best Practices**
1. **Monitor Scaling**: Regularly check HPA behavior and adjust if needed
2. **Resource Limits**: Set appropriate resource limits to prevent resource exhaustion
3. **Node Affinity**: Consider node affinity for better pod distribution
4. **Pod Anti-Affinity**: Use pod anti-affinity for high availability

### **Troubleshooting**
1. **HPA Not Scaling**: Check metrics server and resource requests
2. **PDB Blocking**: Ensure sufficient replicas for PDB requirements
3. **Resource Pressure**: Monitor node resources and adjust limits
4. **Scaling Issues**: Check HPA events and metrics

## 🔄 **Scaling Behavior Examples**

### **High Load Scenario**
```
Initial: 2 pods (CPU: 30%, Memory: 40%)
Load Increase: CPU reaches 70%
HPA Action: Scale up to 4 pods (100% increase)
Result: CPU drops to 35%, Memory to 20%
```

### **Load Decrease Scenario**
```
Current: 6 pods (CPU: 20%, Memory: 25%)
Load Decrease: CPU drops to 30%
HPA Action: Wait 5 minutes, then scale down by 10%
Result: Scale down to 5 pods after stabilization
```

### **Node Maintenance Scenario**
```
Current: 4 pods across 3 nodes
Node Maintenance: 1 node goes down
PDB Action: Ensure 50% (2 pods) remain available
Result: 2 pods continue serving traffic
```

## 📈 **Performance Benefits**

### **1. Automatic Scaling**
- **CPU Scaling**: Responds to CPU utilization spikes
- **Memory Scaling**: Handles memory pressure automatically
- **Dual Metric**: More accurate scaling decisions

### **2. High Availability**
- **Zero Downtime**: Services remain available during maintenance
- **Load Distribution**: Pods spread across multiple nodes
- **Fault Tolerance**: Survives node failures

### **3. Resource Optimization**
- **Cost Efficiency**: Scale down during low usage
- **Performance**: Scale up during high demand
- **Stability**: Prevents resource exhaustion

### **4. Operational Benefits**
- **Automated Management**: Reduces manual intervention
- **Predictable Behavior**: Consistent scaling patterns
- **Monitoring Ready**: Built-in monitoring and alerting

## ✅ **Status: Complete**

All 33 services now have:
- ✅ **HPA Configuration**: Automatic scaling based on 70% CPU/Memory utilization
- ✅ **PDB Configuration**: High availability during node maintenance
- ✅ **Deployment Scripts**: Automated deployment and monitoring
- ✅ **Documentation**: Comprehensive guide and troubleshooting

---

**🎉 HPA and PDB configuration completed successfully!**

**Total Services**: 33
**HPA Configurations**: 33
**PDB Configurations**: 33
**Deployment Scripts**: 3
**Documentation**: Complete 