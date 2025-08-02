# Kafka Cluster Provisioning and Configuration Guide

This document provides a guide on how to provision a Kafka cluster using the provided `kafka_provisioner` script and how to configure your applications to use it.

## 1. Provisioning the Kafka Cluster

The `kafka_provisioner` is a Python script that automates the setup of a horizontally scalable Kafka cluster in High Availability (HA) mode.

### a. Prerequisites

-   Python 3.6+ installed on the machine where you will run the script.
-   SSH access (with username and password) to the target servers where you want to install Kafka.
-   The target servers should be running a compatible OS (Ubuntu or CentOS).

### b. Configuration

1.  **Install Python dependencies:**
    ```bash
    pip install -r kafka_provisioner/requirements.txt
    ```

2.  **Configure your servers:**
    -   Open the `kafka_provisioner/servers.yaml` file.
    -   Update the `servers` list with the IP addresses, usernames, and passwords for the servers where you want to install Kafka.
    -   You can also configure the Kafka version, replication factor, and number of partitions in the `kafka` section of this file.

    **Example `servers.yaml`:**
    ```yaml
    servers:
      - ip: 192.168.1.225
        username: your_user
        password: your_password
      - ip: 192.168.1.226
        username: your_user
        password: your_password
      - ip: 192.168.1.227
        username: your_user
        password: your_password

    kafka:
      version: "3.7.0"
      replication_factor: 3
      partitions: 6
    ```

### c. Run the Deployment Script

Once you have configured your servers, run the deployment script:

```bash
python kafka_provisioner/deploy_kafka.py --config kafka_provisioner/servers.yaml
```

The script will perform the following steps:
1.  Run pre-flight checks on the target servers.
2.  Install Java if it's not already installed.
3.  Download and distribute the Kafka binaries.
4.  Deploy and configure a Zookeeper ensemble.
5.  Deploy and configure the Kafka brokers.
6.  Validate the cluster by creating a topic, producing a message, and consuming it.

## 2. Connecting Applications to the Kafka Cluster

Once the Kafka cluster is up and running, your applications can connect to it using a single endpoint, known as the `bootstrap.servers` list.

### a. How it Works

-   **Single Endpoint:** Your applications don't need to know about every broker in the cluster. You provide a list of one or more brokers in the `bootstrap.servers` configuration property.
-   **Metadata Discovery:** When a client connects to a bootstrap server, it requests metadata about the cluster. This metadata includes information about all the brokers in the cluster, the topics, their partitions, and which broker is the leader for each partition.
-   **Direct Connection:** After getting the metadata, the client can connect directly to the leader broker for the partition it wants to produce to or consume from. This is how Kafka achieves high performance and scalability.
-   **Horizontal Scalability:** If you add more brokers to your cluster, you just need to update the `bootstrap.servers` list in your application's configuration. The clients will automatically discover the new brokers and start using them.

### b. Configuration in Your Ansible Project

In this project, the `bootstrap.servers` list is configured in the `group_vars/all/main.yml` file using the `kafka_broker_ip` variable. This variable is sourced from the environment-specific cluster definition file (e.g., `cluster_vars/dev.yml`).

**`group_vars/all/main.yml`:**
```yaml
common_env:
  # ...
  spring.cloud.stream.kafka.binder.brokers: "{{ kafka_broker_ip }}:29093,{{ kafka_broker_ip }}:39093"
  spring.kafka.producer.bootstrap-servers: "{{ kafka_broker_ip }}:29093,{{ kafka_broker_ip }}:39093"
  spring.kafka.consumer.bootstrap-servers: "{{ kafka_broker_ip }}:29093,{{ kafka_broker_ip }}:39093"
  spring.kafka.bootstrap-servers: "{{ kafka_broker_ip }}:29093,{{ kafka_broker_ip }}:39093"
```

**`cluster_vars/dev.yml`:**
```yaml
kafka_broker_ip: "192.168.1.225"
```

To use the Kafka cluster you have provisioned, you need to ensure that the `kafka_broker_ip` in your cluster definition file points to at least one of the brokers in your Kafka cluster. It is recommended to list at least two brokers in the `bootstrap.servers` list for high availability.

## 3. Traffic Capacity and Performance

The user asked: "is there a way to identify the amount of traffice this cluster can handle giving 5 servers involved?"

This is a complex question with no simple answer, as the performance of a Kafka cluster depends on many factors. Here's a breakdown of the key factors and how you can approach capacity planning:

### a. Factors Affecting Performance

-   **Hardware:**
    -   **CPU:** Kafka is not typically CPU-bound, but a modern multi-core processor is recommended.
    -   **Memory:** Kafka uses the OS's page cache extensively. More memory means better performance. A common recommendation is to have at least 6GB of RAM for Kafka.
    -   **Disk:** Kafka's performance is highly dependent on disk I/O. Fast, dedicated disks (SSDs) are recommended for the log directories.
    -   **Network:** A fast and reliable network is crucial. A 10GbE network is recommended for high-throughput clusters.
-   **Kafka Configuration:**
    -   **Replication Factor:** A higher replication factor provides better fault tolerance but increases the write latency and disk space usage.
    -   **Number of Partitions:** More partitions allow for higher parallelism, but also increase the overhead on the brokers.
    -   **Message Size:** Smaller messages have higher overhead per byte. Batching messages can improve performance.
    -   **Compression:** Enabling compression can reduce the network bandwidth and disk space usage, but it adds some CPU overhead.
-   **Producer and Consumer Configuration:**
    -   **Batch Size:** Larger batches improve throughput but increase latency.
    -   **Acknowledgement (`acks`) setting:** The `acks` setting in the producer determines the number of replicas that must acknowledge a write before it is considered successful. `acks=all` provides the strongest durability guarantees but has the highest latency.

### b. How to Estimate Capacity

1.  **Define Your Workload:**
    -   What is the expected message size?
    -   What is the expected message rate (messages per second)?
    -   What are your latency requirements?
    -   What are your durability requirements (`acks` setting)?

2.  **Run Performance Tests:**
    -   Use Kafka's built-in performance testing tools (`kafka-producer-perf-test.sh` and `kafka-consumer-perf-test.sh`) to simulate your workload and measure the throughput and latency of your cluster.
    -   Start with a single broker and then scale up to your full cluster to see how the performance changes.

3.  **Monitor Your Cluster:**
    -   Use a monitoring tool like Prometheus and Grafana to monitor key metrics like CPU utilization, memory usage, disk I/O, and network I/O.
    -   This will help you identify bottlenecks and tune your cluster for optimal performance.

**In summary, there is no magic number for the amount of traffic a 5-server Kafka cluster can handle. The best way to determine the capacity is to define your workload, run performance tests, and monitor your cluster in a production-like environment.**
