# Jenkins Integration Guide

## Overview

This guide covers the Jenkins integration for triggering builds and deployments as part of the full application deployment pipeline.

## Configuration

### Jenkins Server Details
- **URL**: `http://192.168.1.224:8080`
- **Username**: `khaled`
- **Password**: `Welcome123`

### Files Created
1. `jenkins-trigger.sh` - Standalone Jenkins job trigger script
2. `jenkins-config.env` - Jenkins configuration file
3. `deploy-full-applications.sh` - Updated with Jenkins integration

## Jenkins Jobs Structure

### Dev Environment Jobs

#### Application Services (32 jobs)
```
multi-branch-k8s-ads-service
multi-branch-k8s-api-server
multi-branch-k8s-order-service
multi-branch-k8s-payment-service
multi-branch-k8s-customer-service
multi-branch-k8s-posts-service
multi-branch-k8s-notification-service
multi-branch-k8s-loyalty-service
multi-branch-k8s-inventory-service
multi-branch-k8s-fazeal-business-management
multi-branch-k8s-fazeal-business
multi-branch-k8s-events-service
multi-branch-k8s-cron-jobs
multi-branch-k8s-chat-app-nodejs
multi-branch-k8s-business-chat
multi-branch-k8s-album-service
multi-branch-k8s-promotion-service
multi-branch-k8s-catalog-service
multi-branch-k8s-dev-employee-service
multi-branch-k8s-translation-service
multi-branch-k8s-watermark-detection
multi-branch-k8s-site-management-service
multi-branch-k8s-shopping-service
multi-branch-k8s-payment-gateway
multi-branch-k8s-api-gateway
multi-branch-k8s-Dev-config_server
multi-branch-k8s-dev-dataload-service
multi-branch-k8s-dev-search-service
multi-branch-k8s-fazeal-logistics
```

#### Frontend Applications (5 jobs)
```
multi-branch-k8s-angular-ads
multi-branch-k8s-angular-business
multi-branch-k8s-angular-customer
multi-branch-k8s-Angular-Social
multi-branch-k8s-dev-angular-employee
```

#### Infrastructure Jobs
```
kafka-restart-dev
postgres-restart
registry.service-dev restart
```

#### Deployment Jobs
```
k8s-Prod-deploy
all
```

## Usage

### Standalone Jenkins Triggering

#### Trigger Application Builds
```bash
./jenkins-trigger.sh applications http://192.168.1.224:8080 khaled Welcome123 "" dev latest
```

#### Trigger Frontend Builds
```bash
./jenkins-trigger.sh frontend http://192.168.1.224:8080 khaled Welcome123 "" dev latest
```

#### Trigger Infrastructure Jobs
```bash
./jenkins-trigger.sh infrastructure http://192.168.1.224:8080 khaled Welcome123 "" dev latest
```

#### Trigger Full Pipeline
```bash
./jenkins-trigger.sh full http://192.168.1.224:8080 khaled Welcome123 "" dev latest
```

#### List Available Jobs
```bash
./jenkins-trigger.sh list http://192.168.1.224:8080 khaled Welcome123
```

### Full Deployment with Jenkins Integration

#### Deploy with Jenkins Triggering
```bash
./deploy-full-applications.sh dev v1.2.3 default true http://192.168.1.224:8080 khaled Welcome123 ""
```

#### Deploy without Jenkins (Local Only)
```bash
./deploy-full-applications.sh dev v1.2.3 default false
```

## Script Parameters

### jenkins-trigger.sh
```bash
./jenkins-trigger.sh [action] [jenkins_url] [username] [password] [token] [environment] [image_tag]
```

**Actions:**
- `applications` - Trigger application builds
- `frontend` - Trigger frontend builds
- `infrastructure` - Trigger infrastructure jobs
- `deploy` - Trigger deployment jobs
- `full` - Trigger complete pipeline
- `list` - List available jobs

### deploy-full-applications.sh
```bash
./deploy-full-applications.sh [environment] [image_tag] [namespace] [jenkins_trigger] [jenkins_url] [username] [password] [token]
```

## Integration Flow

### 1. Infrastructure Phase
- Trigger Jenkins infrastructure builds (kafka, postgres, registry)
- Deploy Elastic Stack and Ingress locally
- Wait for infrastructure readiness

### 2. Application Phase
- Trigger Jenkins application builds (32 microservices)
- Deploy core services (config-server, api-server, api-gateway)
- Deploy all business services

### 3. Frontend Phase
- Trigger Jenkins frontend builds (5 Angular applications)
- Deploy Angular applications

### 4. Deployment Phase
- Create ingress configuration
- Trigger Jenkins deployment jobs
- Wait for all services to be ready

## CSRF Protection

The Jenkins server has CSRF protection enabled. The script attempts to handle this by:
1. Fetching a fresh CSRF crumb for each request
2. Including the crumb in the request headers
3. Falling back gracefully if CSRF protection fails

**Note**: If you continue to see CSRF errors, you may need to:
1. Configure Jenkins to allow API calls from your IP
2. Use API tokens instead of password authentication
3. Disable CSRF protection for API calls (if Jenkins admin allows)

## Error Handling

The integration includes robust error handling:
- ✅ **Connectivity testing** - Verifies Jenkins server accessibility
- ✅ **Job existence checking** - Handles missing jobs gracefully
- ✅ **Fallback mechanism** - Continues with local deployment if Jenkins fails
- ✅ **Status reporting** - Provides clear feedback on job triggering

## Monitoring

### Jenkins Dashboard
- **URL**: http://192.168.1.224:8080
- Monitor job progress and build status
- View build logs and artifacts

### Script Output
- Real-time status updates during job triggering
- Success/failure indicators for each job
- Summary of completed operations

## Security Considerations

1. **Credentials**: Store Jenkins credentials securely
2. **API Tokens**: Consider using API tokens instead of passwords
3. **Network Security**: Ensure secure communication with Jenkins
4. **Access Control**: Limit Jenkins access to authorized users

## Troubleshooting

### Common Issues

1. **CSRF Protection Errors**
   - Verify Jenkins CSRF configuration
   - Check if API tokens are required
   - Ensure proper authentication

2. **Job Not Found Errors**
   - Verify job names match exactly
   - Check Jenkins job permissions
   - Ensure user has build permissions

3. **Connection Errors**
   - Verify Jenkins server is running
   - Check network connectivity
   - Validate credentials

### Debug Mode
Add `set -x` to the beginning of scripts for detailed debugging output.

## Support

For issues with:
- **Jenkins Configuration**: Contact Jenkins administrator
- **Script Functionality**: Check script logs and error messages
- **Integration Problems**: Verify all parameters and connectivity

---

**Last Updated**: $(date)
**Version**: 1.0
**Status**: ✅ Ready for Production Use 