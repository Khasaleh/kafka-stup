# Playbook Instructions for `eureka_deploy`

This document provides detailed instructions on how to run the Ansible playbook in this project to deploy a Eureka server cluster.

## 1. `deploy-eureka-cluster.yml`

This playbook deploys a 3-node Eureka server cluster.

### a. How to Run

1.  **Configure your environment:**
    -   Open the `ansible/hosts` file.
    -   Update the `eureka_nodes` list with the IP addresses of your servers.
    -   Update the `ansible_user` and `ansible_password` variables with your SSH credentials.
    -   Place your compiled Eureka server `.jar` file in the `eureka_deploy` directory.

2.  **Run the playbook:**
    ```bash
    ansible-playbook -i ansible/hosts ansible/deploy-eureka-cluster.yml
    ```

### b. Playbook Steps

1.  **Install Prerequisites:** The playbook first installs Docker, Docker Compose, and the required Python libraries on all the target servers.
2.  **Create Deployment Directory:** It then creates a deployment directory at `/opt/eureka`.
3.  **Copy Docker Compose file:** The `docker-compose.yml` file is copied to the deployment directory.
4.  **Generate `application.yml`:** A unique `application.yml` file is generated for each node from the `application.yml.j2` template. This file configures each node to peer with the other nodes in the cluster.
5.  **Start Eureka Service:** Finally, the playbook uses Docker Compose to start the Eureka server in detached mode.

### c. Troubleshooting

-   **"Permission denied" errors:** Ensure that your SSH user has passwordless `sudo` privileges on all the target servers.
-   **"Could not resolve hostname" errors:** Ensure that the IP addresses in your `hosts` file are correct and that your Ansible control node can reach them.
-   **Service fails to start:** Check the logs of the Docker container on the target servers for more information (`docker logs eureka-server`).

### d. Successful Outcome

After a successful run, you will have a fully functional, high-availability Eureka cluster running on your target machines. You can verify this by accessing the Eureka dashboard at `http://<your-eureka-server-ip>:8761`.

## 2. Connecting Services to the Eureka Cluster

Your microservices can connect to the Eureka cluster by using the `eureka.client.serviceUrl.defaultZone` property. This property should be set to a comma-separated list of the Eureka server URLs.

In the `microk8s_ansible_deploy` project, this is handled automatically by the `DISCOVERY_URL` environment variable, which is sourced from the `eureka_ip` variable in your cluster definition file.

**Example:**
If your Eureka servers are running on `192.168.1.101`, `192.168.1.102`, and `192.168.1.103`, you would set the `eureka_ip` in your cluster definition file to one of these IPs, and the `DISCOVERY_URL` would be `http://192.168.1.101:8761`. The microservices will then use this URL to connect to the Eureka cluster and discover the other nodes.
