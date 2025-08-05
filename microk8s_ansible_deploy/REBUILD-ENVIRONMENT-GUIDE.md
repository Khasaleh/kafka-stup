# Full Environment Rebuild Script Guide

## 🎯 **Overview**

The `rebuild-full-environment.sh` script is a comprehensive automation tool that completely rebuilds your Kubernetes environment from scratch. It cleans everything, rebuilds all services, and optionally triggers Jenkins jobs.

## 🚀 **What the Script Does**

### **🧹 Phase 1: Complete Cleanup**
- Deletes all deployments, services, configmaps, secrets
- Removes all HPA, PDB, PVC, PV configurations
- Cleans up ingress, jobs, and pods
- Waits for complete cleanup before proceeding

### **🏗️ Phase 2: Infrastructure Deployment**
- Deploys Elastic Stack (if available)
- Deploys Ingress controllers (if available)
- Sets up basic infrastructure components

### **🚀 Phase 3: Service Deployment**
- Deploys all 33 services using `deploy-full-applications.sh`
- Includes resource allocation, health probes, and configurations
- Handles Jenkins integration if enabled

### **📈 Phase 4: HPA and PDB Deployment**
- Deploys Horizontal Pod Autoscalers for all services
- Deploys Pod Disruption Budgets for high availability
- Ensures automatic scaling and zero downtime

### **🔄 Phase 5: Jenkins Integration**
- Triggers infrastructure builds
- Triggers application builds
- Triggers frontend builds
- Triggers deployment jobs

### **⏳ Phase 6: Verification and Monitoring**
- Waits for all services to be ready
- Verifies deployment status
- Shows final resource counts
- Provides monitoring commands

## 📋 **Usage**

### **Basic Usage**
```bash
# Use all defaults (dev environment, latest tag, default namespace, Jenkins enabled)
./rebuild-full-environment.sh

# Specify environment and image tag
./rebuild-full-environment.sh dev v1.2.3

# Specify namespace
./rebuild-full-environment.sh dev latest default

# Disable Jenkins triggers
./rebuild-full-environment.sh dev latest default false
```

### **Advanced Usage**
```bash
# Full parameter specification
./rebuild-full-environment.sh dev v1.2.3 default true http://192.168.1.224:8080 khaled Welcome123 ""

# Staging environment
./rebuild-full-environment.sh stg latest staging true

# Production environment (be careful!)
./rebuild-full-environment.sh prod v2.0.0 production true
```

## 🔧 **Parameters**

| Parameter | Default | Description |
|-----------|---------|-------------|
| `environment` | `dev` | Environment name (dev, stg, prod) |
| `image_tag` | `latest` | Docker image tag |
| `namespace` | `default` | Kubernetes namespace |
| `jenkins_trigger` | `true` | Enable Jenkins triggers |
| `jenkins_url` | `http://192.168.1.224:8080` | Jenkins server URL |
| `jenkins_user` | `khaled` | Jenkins username |
| `jenkins_password` | `Welcome123` | Jenkins password |
| `jenkins_token` | `""` | Jenkins API token (optional) |

## 📊 **What Gets Deployed**

### **🏗️ Infrastructure Components**
- Elastic Stack (Elasticsearch, Kibana, Logstash)
- Ingress Controllers
- Service Mesh (if configured)

### **🚀 Application Services (33 total)**
- **Frontend Services**: Angular applications
- **Backend Services**: API servers, business logic
- **Infrastructure Services**: Config server, API gateway
- **Data Services**: Database, cache, message queues

### **📈 Scaling and Availability**
- **HPA**: Automatic scaling based on 70% CPU/Memory utilization
- **PDB**: High availability during node maintenance
- **Resource Allocation**: Optimized CPU/Memory limits

## ⚠️ **Important Warnings**

### **🚨 Data Loss Warning**
```bash
# This script will DELETE ALL DATA in the specified namespace
# Make sure to backup any important data before running
```

### **🔒 Production Safety**
```bash
# For production environments, always:
# 1. Test in staging first
# 2. Have a backup strategy
# 3. Schedule maintenance window
# 4. Notify stakeholders
```

### **⏱️ Time Requirements**
- **Cleanup**: 5-10 minutes
- **Deployment**: 15-30 minutes
- **Jenkins Jobs**: 10-20 minutes
- **Total Time**: 30-60 minutes

## 🔍 **Monitoring During Rebuild**

### **Real-time Monitoring**
```bash
# Watch pods being created
kubectl get pods -n default -w

# Watch deployments
kubectl get deployments -n default -w

# Watch HPA scaling
kubectl get hpa -n default -w

# Check events
kubectl get events -n default --sort-by='.lastTimestamp'
```

### **Progress Indicators**
The script provides detailed progress information:
- ✅ Section headers for each phase
- 📊 Step-by-step progress
- ⏳ Waiting indicators
- 🎉 Completion confirmations

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **1. Cleanup Hangs**
```bash
# If cleanup hangs, manually force delete:
kubectl delete pods --all -n default --force --grace-period=0
kubectl delete deployments --all -n default --force --grace-period=0
```

#### **2. Jenkins Connection Issues**
```bash
# Check Jenkins connectivity:
./jenkins-trigger.sh check http://192.168.1.224:8080 khaled Welcome123

# If Jenkins is down, run without Jenkins:
./rebuild-full-environment.sh dev latest default false
```

#### **3. Resource Exhaustion**
```bash
# Check node resources:
kubectl top nodes
kubectl describe nodes

# If resources are low, scale down HPA limits
```

#### **4. Image Pull Issues**
```bash
# Check image pull secrets:
kubectl get secrets -n default

# Verify Docker registry access:
docker pull khsaleh889/familymicroservices:latest
```

### **Recovery Procedures**

#### **Partial Failure Recovery**
```bash
# If script fails partway through:
# 1. Check current status
kubectl get all -n default

# 2. Clean up manually if needed
kubectl delete all --all -n default

# 3. Restart the script
./rebuild-full-environment.sh
```

#### **Complete Reset**
```bash
# If everything is broken:
# 1. Delete namespace completely
kubectl delete namespace default

# 2. Recreate namespace
kubectl create namespace default

# 3. Run rebuild script
./rebuild-full-environment.sh
```

## 📈 **Performance Optimization**

### **Fast Rebuild Tips**
1. **Use Latest Images**: Ensure images are pre-pulled
2. **Optimize Resources**: Set appropriate resource limits
3. **Parallel Deployments**: Use multiple namespaces for testing
4. **Cached Dependencies**: Use persistent volumes for caching

### **Resource Requirements**
- **Minimum**: 4GB RAM, 2 CPU cores
- **Recommended**: 8GB RAM, 4 CPU cores
- **Production**: 16GB RAM, 8 CPU cores

## 🔄 **Automation Integration**

### **CI/CD Pipeline Integration**
```yaml
# Example GitHub Actions workflow
- name: Rebuild Environment
  run: |
    ./rebuild-full-environment.sh ${{ env.ENVIRONMENT }} ${{ env.IMAGE_TAG }} ${{ env.NAMESPACE }} true
```

### **Scheduled Rebuilds**
```bash
# Cron job for nightly rebuilds
0 2 * * * /path/to/rebuild-full-environment.sh dev latest default true
```

### **Blue-Green Deployment**
```bash
# Blue environment
./rebuild-full-environment.sh dev latest blue true

# Green environment
./rebuild-full-environment.sh dev latest green true

# Switch traffic
kubectl patch service main-service -p '{"spec":{"selector":{"env":"green"}}}'
```

## 📊 **Success Metrics**

### **Deployment Success Indicators**
- ✅ All 33 services deployed
- ✅ All pods in Running state
- ✅ All HPA and PDB configured
- ✅ Jenkins jobs completed successfully
- ✅ No error events in namespace

### **Performance Indicators**
- 🚀 Deployment time < 30 minutes
- 📈 Resource utilization < 80%
- 🔄 Zero downtime during rebuild
- 🛡️ All health checks passing

## 🎯 **Best Practices**

### **Before Running**
1. **Backup Data**: Export important configurations
2. **Check Resources**: Ensure sufficient cluster capacity
3. **Notify Team**: Inform stakeholders of maintenance
4. **Test First**: Run in staging environment

### **During Execution**
1. **Monitor Progress**: Watch the script output
2. **Check Logs**: Monitor application logs
3. **Verify Health**: Check service health endpoints
4. **Document Issues**: Note any problems for follow-up

### **After Completion**
1. **Verify Services**: Test all critical endpoints
2. **Check Scaling**: Verify HPA is working
3. **Monitor Performance**: Watch resource usage
4. **Update Documentation**: Record any changes

## 📞 **Support and Maintenance**

### **Regular Maintenance**
- **Weekly**: Run rebuild to test automation
- **Monthly**: Update images and configurations
- **Quarterly**: Review and optimize resource allocation

### **Emergency Procedures**
- **Service Down**: Check pod status and logs
- **Scaling Issues**: Verify HPA configuration
- **Resource Exhaustion**: Scale down or add resources
- **Jenkins Issues**: Run without Jenkins triggers

---

**🎉 The rebuild script provides a complete, automated solution for environment management!**

**Key Benefits:**
- **Complete Automation**: One command rebuilds everything
- **Zero Downtime**: Proper cleanup and deployment sequence
- **Comprehensive Monitoring**: Real-time status and verification
- **Error Handling**: Robust error recovery and troubleshooting
- **Flexible Configuration**: Supports multiple environments and parameters 