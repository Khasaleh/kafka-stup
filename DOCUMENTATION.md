# Ansible MicroK8s Deployment Guide

This document provides a comprehensive guide on how to use this Ansible project to deploy a MicroK8s cluster and a suite of microservices.

## Project Structure

The project is structured to be flexible and scalable, allowing for easy management of multiple environments.

-   **`ansible/`**: This directory contains all the Ansible-related files.
    -   **`cluster_vars/`**: This directory contains the environment-specific cluster definition files. All environment-specific configuration should be done here.
        -   **`dev.yml`**: The cluster definition file for the `dev` environment.
        -   **`stg.yml`**: The cluster definition file for the `stg` environment.
    -   **`group_vars/`**: This directory contains the variable files for different environments.
        -   **`all/main.yml`**: Contains variables that are common to all environments.
        -   **`all/vault.yml`**: Contains all the secrets, encrypted with Ansible Vault.
        -   **`dev/main.yml`**: A placeholder file to mark the `dev` environment.
        -   **`stg/main.yml`**: A placeholder file to mark the `stg` environment.
    -   **`roles/`**: This directory contains all the Ansible roles.
        -   **`app_deployer/`**: A generic role to deploy a microservice.
        -   **`dataload_service_deployer/`**: A specific role to deploy the `dataload-service`.
        -   **`microk8s_cleanup/`**: A role to clean up existing MicroK8s installations.
        -   **`microk8s_install/`**: A role to install MicroK8s.
        -   **`microk8s_master/`**: A role to initialize the MicroK8s master node.
        -   **`microk8s_worker/`**: A role to join worker nodes to the cluster.
    -   **`ingress/`**: Contains all the Kubernetes manifests for the NGINX Ingress Controller.
    -   **`vars/services.yml`**: This file contains the list of all the microservices to be deployed.
    -   **`install-cluster.yml`**: The playbook to install the MicroK8s cluster.
    -   **`deploy-application.yml`**: The main playbook to deploy all the applications.
    -   **`deploy-elastic-stack.yml`**: The playbook to deploy Elasticsearch and Kibana.
    -   **`deploy-ingress.yml`**: The playbook to deploy the NGINX Ingress Controller.
    -   **`deploy-dataload-service.yml`**: The playbook to deploy the `dataload-service`.
    -   **`hosts.j2`**: A Jinja2 template for the Ansible inventory file.
    -   **`ansible-vault-password.txt`**: The password file for Ansible Vault.

## Configuration

Before running the playbooks, you need to configure your environment.

### 1. Configure the Cluster

All environment-specific configuration is done in the `cluster_vars/` directory. Create a new file for your environment (e.g., `my-env.yml`) or modify one of the existing ones (`dev.yml`, `stg.yml`).

**Example `cluster_vars/dev.yml`:**

```yaml
---
# Development Environment Cluster Definition
env: "dev"

# Kubernetes Cluster
kube_masters:
  - 192.168.1.200
  - 192.168.1.205
kube_workers:
  - 192.168.1.207
  - 192.168.1.208
  - 192.168.1.209

# Service Endpoints
kafka_broker_ip: "192.168.1.225"
db_host: "192.168.1.213"
redis_host: "192.168.1.217"
eureka_ip: "192.168.1.212"
dataload_db_host: "192.168.1.213"

# Ingress
ingress_domain: "fazeal.com"

# MicroK8s
microk8s_version: "1.28/stable"
```

### 2. Configure the Services

The list of all microservices to be deployed is defined in `vars/services.yml`. You can add, remove, or modify the services in this file.

### 3. Configure the Secrets

All secrets are stored in `group_vars/all/vault.yml`. To edit this file, you first need to decrypt it:

```bash
ansible-vault decrypt group_vars/all/vault.yml --vault-password-file ansible-vault-password.txt
```

After making your changes, re-encrypt the file:

```bash
ansible-vault encrypt group_vars/all/vault.yml --vault-password-file ansible-vault-password.txt
```

## Connecting Services to Eureka and Kafka

The microservices in this project are configured to connect to the Eureka and Kafka clusters using environment variables that are injected into the pods from ConfigMaps. The values for these environment variables are sourced from the centralized configuration files in this Ansible project.

### a. Eureka Connection

The connection to the Eureka cluster is configured using the `DISCOVERY_URL` and `EUREKA_HOST` environment variables. These are defined in the `common_env` section of `group_vars/all/main.yml` and are sourced from the `eureka_ip` variable in your environment-specific cluster definition file (e.g., `cluster_vars/dev.yml`).

**`cluster_vars/dev.yml`:**
```yaml
eureka_ip: "192.168.1.212"
```

**`group_vars/all/main.yml`:**
```yaml
common_env:
  DISCOVERY_URL: "http://{{ eureka_ip }}:8761"
  EUREKA_HOST: "{{ eureka_ip }}"
```

When the `deploy-application.yml` playbook is run, it generates a `ConfigMap` for each service that includes these environment variables. The services then use these variables to register with and discover other services from the Eureka cluster.

### b. Kafka Connection

The connection to the Kafka cluster is configured using the `spring.kafka.bootstrap-servers` and related properties. These are defined in the `common_env` section of `group_vars/all/main.yml` and are sourced from the `kafka_broker_ip` variable in your environment-specific cluster definition file.

**`cluster_vars/dev.yml`:**
```yaml
kafka_broker_ip: "192.168.1.225"
```

**`group_vars/all/main.yml`:**
```yaml
common_env:
  spring.cloud.stream.kafka.binder.brokers: "{{ kafka_broker_ip }}:29093,{{ kafka_broker_ip }}:39093"
  spring.kafka.producer.bootstrap-servers: "{{ kafka_broker_ip }}:29093,{{ kafka_broker_ip }}:39093"
  spring.kafka.consumer.bootstrap-servers: "{{ kafka_broker_ip }}:29093,{{ kafka_broker_ip }}:39093"
  spring.kafka.bootstrap-servers: "{{ kafka_broker_ip }}:29093,{{ kafka_broker_ip }}:39093"
```

The `bootstrap.servers` property provides a list of one or more brokers that the Kafka client can connect to to discover the rest of the cluster.

## Running the Playbooks

### 1. Install the MicroK8s Cluster

To install the MicroK8s cluster, run the `install-cluster.yml` playbook. You need to specify the environment you want to deploy to using the `-e "env=<your-env>"` flag.

```bash
ansible-playbook -i ansible/hosts install-cluster.yml -e "env=dev"
```

This command will:
1.  Clean up any existing MicroK8s installation on the nodes.
2.  Install MicroK8s on all the master and worker nodes.
3.  Initialize the cluster on the primary master.
4.  Join the worker nodes to the cluster.

### 2. Deploy the Applications

To deploy all the applications, run the `deploy-application.yml` playbook. You also need to specify the environment.

```bash
ansible-playbook deploy-application.yml -e "env=dev"
```

This command will:
1.  Deploy the Elastic Stack (Elasticsearch and Kibana).
2.  Deploy the NGINX Ingress Controller.
3.  Deploy the `dataload-service`.
4.  Deploy all the microservices defined in `vars/services.yml`.
5.  Create the Docker Hub secret.
6.  Create the Ingress resources for the services that have them defined.
