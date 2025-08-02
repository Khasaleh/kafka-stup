# Automated MicroK8s Cluster and Application Deployment with Ansible

This project provides a complete automation solution for provisioning a multi-node, high-availability MicroK8s cluster and deploying containerized applications to it.

## Project Structure

- `ansible/`: Contains all the Ansible assets.
  - `hosts`: **Sample inventory file.** This is the main file you need to configure.
  - `install-cluster.yml`: The playbook to provision the MicroK8s cluster itself.
  - `deploy-application.yml`: An example playbook that deploys a sample application using the `app_deployer` role.
  - `roles/`: Contains Ansible roles.
    - `app_deployer/`: A reusable role to deploy any containerized application.
      - `tasks/main.yml`: The main task file for the role.
      - `templates/`: Contains Jinja2 templates for all the Kubernetes manifests (Deployment, Service, HPA, etc.).
      - `defaults/main.yml`: Defines the default variables for deploying an application.

## Part 1: Provisioning the MicroK8s Cluster

### Step 1: Configure the Inventory

1.  Open the `ansible/hosts` file.
2.  Under the `[kube_masters]` group, replace the placeholder IPs with the IP addresses of your master nodes. The first node in this list will be treated as the primary master for initialization.
3.  Under the `[kube_workers]` group, replace the placeholder IPs with the IP addresses of your worker nodes.
4.  Ensure the `ansible_user` variable is set to a user that has passwordless `sudo` access on all target nodes.

### Step 2: Run the Cluster Installation Playbook

From your Ansible control node, navigate to the `ansible` directory and run the playbook:

```bash
cd ansible
ansible-playbook install-cluster.yml
```

This playbook will connect to all nodes, install MicroK8s, and form a cluster.

### Step 3: Get Kubeconfig for Remote Access

After the playbook finishes, you need to get the `kubeconfig` file from the primary master to control your cluster from the Ansible node (or your local machine).

1.  SSH into your primary master node (the first IP in the `kube_masters` group).
2.  Run `microk8s config`.
3.  Copy the output and save it to a file on your Ansible control node, typically at `~/.kube/config`. You may need to replace the `127.0.0.1` server address in the config file with the actual IP of the master node if you are accessing it from a remote machine.

## Part 2: Deploying an Application to the Cluster

### Step 1: Customize the Application Deployment Playbook

1.  Open the `ansible/deploy-application.yml` file. This file contains a full example of how to deploy an NGINX web server.
2.  To deploy your own application, modify the variables under the `vars:` section:
    - `app_name`: A unique name for your application.
    - `app_namespace`: The Kubernetes namespace to deploy into.
    - `app_image`: The Docker image you want to deploy.
    - `app_replicas`, `app_container_port`, etc.: Customize all other parameters as needed.
3.  **For Secrets**: It is **highly recommended** to use Ansible Vault to encrypt sensitive data. To do this, create an encrypted file (e.g., `secrets.yml`) and load it in the playbook using `vars_files`. Do not store plaintext passwords in the playbook.

### Step 2: Run the Application Deployment Playbook

From the `ansible` directory, run the playbook:

```bash
ansible-playbook deploy-application.yml
```

This playbook runs locally on your control node. It will generate all the necessary Kubernetes manifests (ConfigMap, Secret, Deployment, Service, HPA, Ingress) from the templates and apply them to your cluster using the `kubeconfig` file you set up in Part 1. Your application will now be deployed and managed by Kubernetes.
