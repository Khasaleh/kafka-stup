#!/bin/bash

# Create missing service files
for service in angular-employee catalog-service customer-service employees-service payment-service translation-service watermark-detection; do
    echo "Creating files for $service"
    
    # Create deployment.yml
    cat > "application_deployment/dev/$service/deployment.yml" << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $service
  labels:
    app: $service
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $service
  template:
    metadata:
      labels:
        app: $service
    spec:
      imagePullSecrets:
        - name: dockerhub-secret
      containers:
        - name: $service
          image: khsaleh889/familymicroservices:\$IMAGE
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
              protocol: TCP
          env:
            - name: SERVICE_NAME
              value: "$service"
          livenessProbe:
            failureThreshold: 3
            initialDelaySeconds: 30
            periodSeconds: 10
            successThreshold: 1
            tcpSocket:
              port: 80
            timeoutSeconds: 3
          readinessProbe:
            failureThreshold: 3
            initialDelaySeconds: 5
            periodSeconds: 10
            successThreshold: 1
            tcpSocket:
              port: 80
            timeoutSeconds: 1
EOF

    # Create configmap.yml
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

    # Create secret.yml
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

    # Create service.yml
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

echo "Created files for all missing services" 