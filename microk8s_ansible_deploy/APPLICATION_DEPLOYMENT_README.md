# Application Deployment from Files

This directory contains the new approach for deploying services using pre-generated Kubernetes manifests.

## Directory Structure

```
application_deployment/
└── dev/
    ├── config-server/
    │   ├── deployment.yml
    │   ├── configmap.yml
    │   ├── secret.yml
    │   └── service.yml
    ├── api-server/
    │   ├── deployment.yml
    │   ├── configmap.yml
    │   ├── secret.yml
    │   └── service.yml
    └── ... (for each service)
```

## How to Use

### 1. Deploy Config Server Only (Test)
```bash
ansible-playbook ansible/deploy-config-server.yml
```

### 2. Deploy All Services
```bash
ansible-playbook ansible/deploy-from-files.yml -e "env=dev"
```

### 3. Deploy Specific Service
```bash
# Edit the playbook to include only the service you want
ansible-playbook ansible/deploy-from-files.yml -e "env=dev"
```

## Benefits

1. **✅ No YAML parsing errors** - Each manifest is a complete, valid YAML file
2. **✅ Service-specific configuration** - Each service gets exactly what it needs
3. **✅ Easy to review** - You can check the generated manifests before deployment
4. **✅ Easy to debug** - Each service has its own folder with all manifests
5. **✅ No complex templating** - Simple, reliable deployment

## Current Status

- ✅ **config-server** - Complete with all environment variables
- ✅ **api-server** - Complete with all environment variables
- ⏳ **All other services** - Basic structure created, need to add specific environment variables

## Complete Service List

The following services are now included in the deployment:

1. **config-server** ✅
2. **api-server** ✅
3. **site-management-service**
4. **shopping-service**
5. **posts-service**
6. **payment-gateway**
7. **order-service**
8. **notification-service**
9. **loyalty-service**
10. **inventory-service**
11. **fazeal-business-management**
12. **fazeal-business**
13. **events-service**
14. **angular-customer-ssr**
15. **cron-jobs**
16. **chat-app**
17. **business-chat**
18. **api-gateway**
19. **angular-dev**
20. **angular-customer**
21. **angular-business**
22. **angular-ads**
23. **angular-employee**
24. **album-service**
25. **ads-service**
26. **promotion-service**
27. **catalog-service**
28. **customer-service**
29. **employees-service**
30. **payment-service**
31. **translation-service**
32. **watermark-detection**

## Adding Environment Variables

To add environment variables for a service:

1. Edit `application_deployment/dev/{service-name}/deployment.yml`
2. Add environment variables in the `env` section
3. Run the deployment playbook

## Example: Config Server

The config-server deployment contains exactly what it needs:

```yaml
env:
  - name: DISCOVERY_URL
    value: "http://192.168.1.212:8761"
  - name: BUSINESS_MANGE_DB_HOST
    value: "192.168.1.213"
  - name: spring.profiles.active
    value: "dev"
  - name: CONFIG_USER
    value: "Khsaleh2024"
  - name: CONFIG_PASS
    value: "ATBBsS3gExWYHwV4nWSjgAR3ypSW4FCC4191"
```

No extra environment variables, no missing secrets - exactly what the service needs! 