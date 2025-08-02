# Playbook Instructions for `kafka_provisioner`

This document provides detailed instructions on how to run the `deploy_kafka.py` script to provision a Kafka cluster.

## 1. `deploy_kafka.py`

This script automates the setup of a horizontally scalable Kafka cluster in High Availability (HA) mode.

### a. How to Run

1.  **Configure your servers:**
    -   Open the `servers.yaml` file.
    -   Update the `servers` list with the IP addresses, usernames, and passwords for the servers where you want to install Kafka.
    -   You can also configure the Kafka version, replication factor, and number of partitions in the `kafka` section of this file.

2.  **Install Python dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

3.  **Run the deployment script:**
    ```bash
    python deploy_kafka.py --config servers.yaml
    ```

### b. Script Steps

1.  **Pre-flight Checks:** The script first connects to each server to verify SSH access and determine the OS distribution (Ubuntu or CentOS).
2.  **Install Dependencies:** It then ensures that Java is installed on all the servers.
3.  **Distribute Kafka:** The script downloads the specified version of Kafka, distributes it to all the servers, and creates a symbolic link.
4.  **Deploy Zookeeper:** It then deploys and configures a Zookeeper ensemble across all the nodes.
5.  **Deploy Kafka Brokers:** The script then deploys and configures the Kafka brokers on all the nodes.
6.  **Validate Cluster:** Finally, it runs a validation test to ensure the cluster is working correctly. This involves creating a topic, producing a message, and consuming it.

### c. Troubleshooting

-   **"Failed to connect" errors:** Ensure that the IP addresses, usernames, and passwords in your `servers.yaml` file are correct and that your machine can reach the target servers.
-   **"Command failed" errors:** Check the logs for more information. The script will log the standard error from any failed commands.
-   **Validation fails:** If the cluster validation fails, it could be due to a number of issues, such as network connectivity problems between the brokers or a misconfiguration in the `server.properties` file. Check the Kafka logs on the brokers for more information (`/opt/kafka/logs/server.log`).

### d. Successful Outcome

After a successful run, you will have a fully functional Kafka cluster running on your target servers. The script will print "🚀 Kafka Cluster Deployment and Validation Complete! 🚀" to the console.

## 2. Connecting Services to the Kafka Cluster

Your microservices can connect to the Kafka cluster by using the `spring.kafka.bootstrap-servers` property. This property should be set to a comma-separated list of the Kafka broker URLs.

In the `microk8s_ansible_deploy` project, this is handled automatically by the `kafka_broker_ip` variable in your cluster definition file.

**Example:**
If your Kafka brokers are running on `192.168.1.225`, `192.168.1.226`, and `192.168.1.227`, you would set the `kafka_broker_ip` in your cluster definition file to one of these IPs, and the `bootstrap-servers` properties would be configured to use this IP. The microservices will then use this to connect to the Kafka cluster and discover the other brokers.
