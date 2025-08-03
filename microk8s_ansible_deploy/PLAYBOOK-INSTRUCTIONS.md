# Playbook Instructions for `microk8s_ansible_deploy`

This document provides detailed instructions on how to run the Ansible playbooks in this project to deploy a MicroK8s cluster and the application suite.

## 1. `install-cluster.yml`

This playbook installs and configures a MicroK8s cluster on your target servers.

### a. How to Run

1.  **Configure your inventory:**
    -   Open the `ansible/hosts` file.
    -   Define a `kube_cluster` group with all your master and worker nodes.
    -   Define `kube_masters` and `kube_workers` groups with the corresponding nodes.
    -   Ensure your inventory is configured correctly for Ansible to connect (e.g., `ansible_host`, `ansible_user`).

2.  **Configure your environment:**
    -   Open the `ansible/cluster_vars/<your-env>.yml` file (e.g., `ansible/cluster_vars/dev.yml`).
    -   Update the `kube_masters` and `kube_workers` lists with the inventory hostnames of your servers.
    -   Update the `microk8s_version` to specify the channel for the MicroK8s snap (e.g., `1.28/stable`).
    -   Ensure you have SSH access to all the servers from your Ansible control node.

3.  **Run the playbook:**
    ```bash
    ansible-playbook -i ansible/hosts install-cluster.yml -e "env=<your-env>"
    ansible-playbook -i ansible/hosts ansible/install-cluster.yml -e "env=dev" --vault-password-file ansible/ansible-vault-password.txt


Here is the command to run that will ask for your password:

ansible-playbook -i ansible/hosts ansible/install-cluster.yml -e "env=dev" --vault-password-file ansible/ansible-vault-password.txt --ask-pass
When you run this, it will first prompt you for the SSH password:

SSH password:
You can type your password there. It should then use that password to connect to all the servers in your inventory.


    ```
    Replace `<your-env>` with the name of your environment (e.g., `dev`).

### b. Playbook Steps

The `install-cluster.yml` playbook executes in several plays:

1.  **Install MicroK8s:**
    -   Installs the MicroK8s snap on all nodes in the `kube_cluster` group. The version is determined by the `microk8s_version` variable in your environment's `cluster_vars` file.
    -   Adds the `ansible_user` to the `microk8s` group to allow `kubectl` access.

2.  **Initialize Primary Master:**
    -   Runs only on the first host in the `kube_masters` group.
    -   Waits for MicroK8s to be ready.
    -   Generates join tokens for other masters and for worker nodes.
    -   Enables essential MicroK8s addons: `dns`, `hostpath-storage`, and `ingress`.

3.  **Join Other Masters:**
    -   Runs on the rest of the hosts in the `kube_masters` group.
    -   Joins them to the cluster as master nodes.

4.  **Join Worker Nodes:**
    -   Runs on all hosts in the `kube_workers` group.
    -   Joins them to the cluster as worker nodes.

### c. Troubleshooting

-   **"Permission denied" errors:** Ensure that your SSH user has passwordless `sudo` privileges on all the target servers.
-   **"Could not resolve hostname" errors:** Ensure that the hostnames in your inventory file are correct and that your Ansible control node can reach them.
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
