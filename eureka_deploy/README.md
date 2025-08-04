# Eureka HA Cluster Deployment with Ansible and Docker

This project provides an automated way to deploy a high-availability (HA) Eureka cluster on a set of virtual machines using Ansible and Docker Compose.

## Project Structure

- `Dockerfile`: Defines the container image for the Eureka server application.
- `docker-compose.yml`: A Docker Compose file to run the Eureka server container.
- `config/application.yml`: A sample configuration file for a single Eureka node. This is not used directly by the playbook.
- `ansible/`: Contains the Ansible automation assets.
  - `ansible.cfg`: Basic Ansible configuration.
  - `hosts`: A **sample inventory file**. You must edit this file to match your infrastructure.
  - `deploy-eureka-cluster.yml`: The main Ansible playbook for deploying the cluster.
  - `templates/application.yml.j2`: A Jinja2 template used by the playbook to generate a unique `application.yml` for each node in the cluster.

## Authentication

This project uses password-based authentication. Please see the [AUTHENTICATION.md](../AUTHENTICATION.md) file for instructions on how to set up and use passwords.

## Prerequisites

1.  **Ansible Control Node**: A machine with Ansible installed where you will run the playbook from.
2.  **Target VMs**: A set of servers (VMs or bare metal) with a supported Linux distribution (e.g., Ubuntu, CentOS).
3.  **SSH Access**: You must have SSH access from the Ansible control node to the target VMs. The user must have `sudo` privileges.
4.  **Eureka Server JAR**: This automation is for deploying a pre-built Eureka server. You need to have the application `.jar` file ready. By default, the `docker-compose.yml` assumes it is named `eureka-server.jar` in the project root.

## Deployment Steps

1.  **Clone the Project**:
    ```bash
    git clone <this-repo>
    cd eureka_deploy
    ```

2.  **Place Your JAR file**:
    - Place your compiled Eureka server `.jar` file in the `eureka_deploy` directory. If it's not named `eureka-server.jar`, you will need to update the `JAR_FILE` argument in `docker-compose.yml`.

3.  **Configure the Ansible Inventory**:
    - Open the `ansible/hosts` file.
    - Replace the placeholder IP addresses (`192.168.1.101`, etc.) with the actual IP addresses of your target VMs.
    - Ensure the `eureka_hostname` for each node is a unique and resolvable name that your microservices can use.
    - Update the `ansible_user` if you are not connecting as `root`.

4.  **Run the Ansible Playbook**:
    - Navigate to the `ansible` directory:
      ```bash
      cd ansible
      ```
    - Run the playbook:
      ```bash
      ansible-playbook deploy-eureka-cluster.yml
      ```

## How it Works

The playbook will perform the following actions on each target host:
1.  Install Docker, Docker Compose, and the required Python libraries.
2.  Create a deployment directory at `/opt/eureka`.
3.  Copy the `docker-compose.yml` file.
4.  Generate a unique `application.yml` file from the `application.yml.j2` template. The template logic ensures that each node is configured to peer with all other nodes in the cluster, creating the HA mesh.
5.  Use Docker Compose to build the Eureka server image (if not already built and tagged as `fazeal/eureka-server`) and start the service in detached mode.

After the playbook completes, you will have a fully functional, high-availability Eureka cluster running on your target machines.
