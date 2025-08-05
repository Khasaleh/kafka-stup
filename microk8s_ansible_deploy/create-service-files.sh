#!/bin/bash

# Create service directories
mkdir -p application_deployment/dev/{site-management-service,shopping-service,posts-service,payment-gateway,order-service,notification-service,loyalty-service,inventory-service,fazeal-business-management,fazeal-business,events-service,angular-customer-ssr,cron-jobs,chat-app,business-chat,api-gateway,angular-dev,angular-customer,angular-business,album-service,ads-service,promotion-service}

echo "Created service directories"

# Create configmap files for each service
for service in site-management-service shopping-service posts-service payment-gateway order-service notification-service loyalty-service inventory-service fazeal-business-management fazeal-business events-service angular-customer-ssr cron-jobs chat-app business-chat api-gateway angular-dev angular-customer angular-business album-service ads-service promotion-service; do
    cat > "application_deployment/dev/$service/configmap.yml" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: $service-config
  namespace: default
  labels:
    app: $service
data:
  SERVICE_NAME: "$service"
EOF
done

# Create secret files for each service
for service in site-management-service shopping-service posts-service payment-gateway order-service notification-service loyalty-service inventory-service fazeal-business-management fazeal-business events-service angular-customer-ssr cron-jobs chat-app business-chat api-gateway angular-dev angular-customer angular-business album-service ads-service promotion-service; do
    cat > "application_deployment/dev/$service/secret.yml" << EOF
apiVersion: v1
kind: Secret
metadata:
  name: $service-secret
  namespace: default
  labels:
    app: $service
type: Opaque
data:
  SERVICE_NAME: "$(echo -n $service | base64)"
EOF
done

# Create service files for each service
for service in site-management-service shopping-service posts-service payment-gateway order-service notification-service loyalty-service inventory-service fazeal-business-management fazeal-business events-service angular-customer-ssr cron-jobs chat-app business-chat api-gateway angular-dev angular-customer angular-business album-service ads-service promotion-service; do
    cat > "application_deployment/dev/$service/service.yml" << EOF
apiVersion: v1
kind: Service
metadata:
  name: $service
  namespace: default
  labels:
    app: $service
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: 80
      protocol: TCP
      name: http
  selector:
    app: $service
EOF
done

echo "Created basic configmap, secret, and service files for all services"
echo "You can now manually add the specific environment variables for each service" 