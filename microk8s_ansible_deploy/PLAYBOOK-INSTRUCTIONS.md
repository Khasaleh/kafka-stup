# Playbook Instructions for `microk8s_ansible_deploy`

This document provides detailed instructions on how to run the Ansible playbooks in this project to deploy a MicroK8s cluster and the application suite.

## 1. `install-cluster.yml`

This playbook installs and configures a MicroK8s cluster on your target servers.

### a. How to Run

1.  **Configure your environment:**
    -   Open the `ansible/cluster_vars/<your-env>.yml` file (e.g., `ansible/cluster_vars/dev.yml`).
    -   Update the `kube_masters` and `kube_workers` lists with the IP addresses of your servers.
    -   Update the `microk8s_version` if you want to install a different version of MicroK8s.
    -   Ensure you have SSH access to all the servers from your Ansible control node.

2.  **Run the playbook:**
    ```bash
    ansible-playbook -i ansible/hosts install-cluster.yml -e "env=<your-env>"
    ```
    Replace `<your-env>` with the name of your environment (e.g., `dev`).

### b. Playbook Steps

1.  **Generate `hosts` file:** The playbook first generates an Ansible inventory file (`hosts`) from the `hosts.j2` template using the server IPs from your cluster definition file.
2.  **Clean up existing MicroK8s installation:** The `microk8s_cleanup` role is run on all nodes to ensure a clean installation. This role will:
    -   Stop the MicroK8s service.
    -   Reset the MicroK8s cluster.
    -   Remove the MicroK8s snap.
3.  **Install MicroK8s:** The `microk8s_install` role is run on all nodes to install the version of MicroK8s specified in your cluster definition file.
4.  **Initialize the master node:** The `microk8s_master` role is run on the first master node to initialize the MicroK8s cluster.
5.  **Join worker nodes:** The `microk8s_worker` role is run on all the worker nodes to join them to the cluster.

### c. Troubleshooting

-   **"Permission denied" errors:** Ensure that your SSH user has passwordless `sudo` privileges on all the target servers.
-   **"Could not resolve hostname" errors:** Ensure that the IP addresses in your cluster definition file are correct and that your Ansible control node can reach them.
-   **Installation fails:** If the MicroK8s installation fails, you can check the logs on the target servers for more information (`/var/log/syslog` or `journalctl -u snap.microk8s.daemon-containerd`).

### d. Successful Outcome

After a successful run, you will have a fully functional MicroK8s cluster running on your target servers. You can verify this by running `microk8s kubectl get nodes` on the primary master node.

## 2. `deploy-application.yml`

This playbook deploys the entire application suite to your MicroK8s cluster.

### a. How to Run

1.  **Configure your environment:**
    -   Ensure that your `ansible/cluster_vars/<your-env>.yml` file is correctly configured with all the necessary service endpoints.
    -   Review the `ansible/vars/services.yml` file to ensure that all the services you want to deploy are defined.
    -   Ensure that you have a valid `~/.kube/config` file that points to your MicroK8s cluster. You can get this from your primary master node by running `microk8s config`.

2.  **Run the playbook:**
    ```bash
    ansible-playbook deploy-application.yml -e "env=<your-env>"
    ```
    Replace `<your-env>` with the name of your environment (e.g., `dev`).

### b. Playbook Steps

1.  **Deploy Elastic Stack:** The `deploy-elastic-stack.yml` playbook is run to deploy Elasticsearch and Kibana using the official Elastic Helm charts.
2.  **Deploy NGINX Ingress Controller:** The `deploy-ingress.yml` playbook is run to deploy the NGINX Ingress Controller from a set of Kubernetes manifests.
3.  **Deploy `dataload-service`:** The `deploy-dataload-service.yml` playbook is run to deploy the `dataload-service` and its associated resources (PV, PVC, ConfigMap, Secret).
4.  **Deploy all other services:** The playbook then loops through the list of services in `vars/services.yml` and deploys each one using the `app_deployer` role. For each service, it will create:
    -   A `ConfigMap`.
    -   A `Secret`.
    -   A `Deployment`.
    -   A `Service`.
    -   A `HorizontalPodAutoscaler`.
    -   An `Ingress` resource (if configured).
5.  **Create Docker Hub secret:** A Kubernetes secret is created to allow the cluster to pull images from your private Docker Hub repository.

### c. Troubleshooting

-   **"ImagePullBackOff" errors:** Ensure that the Docker Hub secret is created correctly and that the image names and tags in `vars/services.yml` are correct.
-   **"CrashLoopBackOff" errors:** Check the logs of the failing pods for more information (`kubectl logs <pod-name>`). This is often due to a configuration error (e.g., incorrect database credentials).
-   **Ingress not working:** Ensure that the NGINX Ingress Controller is running correctly and that the hostnames in your Ingress resources are correct.

### d. Successful Outcome

After a successful run, all your applications will be deployed and running in your MicroK8s cluster. You can verify this by running `kubectl get pods -n <namespace>` and `kubectl get services -n <namespace>`.
