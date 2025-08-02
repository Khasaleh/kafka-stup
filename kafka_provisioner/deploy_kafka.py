import argparse
import yaml
import paramiko
import logging
import sys
import os
import urllib.request
import io
import time

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# --- All helper and deployment functions are defined here ---
def connect_ssh(ip, username, password):
    try:
        ssh_client = paramiko.SSHClient()
        ssh_client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        ssh_client.connect(hostname=ip, username=username, password=password, timeout=10)
        return ssh_client
    except Exception as e:
        logging.error(f"Failed to connect to {ip}: {e}")
        return None

def execute_command(ssh_client, command, ignore_errors=False):
    try:
        stdin, stdout, stderr = ssh_client.exec_command(command, get_pty=True)
        exit_code = stdout.channel.recv_exit_status()
        stdout_str = stdout.read().decode('utf-8').strip()
        stderr_str = stderr.read().decode('utf-8').strip()
        if exit_code != 0 and not ignore_errors:
            logging.error(f"Command '{command}' failed with exit code {exit_code}. Stderr:\n{stderr_str}")
        return stdout_str, stderr_str, exit_code
    except Exception as e:
        logging.error(f"An error occurred: {e}")
        return None, str(e), -1

def upload_content(ssh_client, content, remote_path):
    try:
        sftp = ssh_client.open_sftp()
        with io.BytesIO(content.encode('utf-8')) as f:
            sftp.putfo(f, remote_path)
        sftp.close()
        return True
    except Exception as e:
        logging.error(f"Failed to upload content to {remote_path}: {e}")
        return False

def run_preflight_checks(servers):
    logging.info("--- Starting Pre-flight Checks ---")
    all_checks_passed = True
    for server in servers:
        ssh = connect_ssh(server['ip'], server['username'], server['password'])
        if not ssh: all_checks_passed = False; continue
        out, _, code = execute_command(ssh, "cat /etc/os-release", ignore_errors=True)
        if code == 0:
            os_info = dict(l.split('=', 1) for l in out.split('\n') if '=' in l)
            server['os_id'] = os_info.get('ID', '').strip('"')
        else: all_checks_passed = False
        ssh.close()
    if not all_checks_passed: sys.exit("Pre-flight checks failed.")
    logging.info("--- Pre-flight Checks Succeeded ---")

def install_dependencies(servers):
    logging.info("--- Starting Dependency Installation ---")
    for server in servers:
        ssh = connect_ssh(server['ip'], server['username'], server['password'])
        if not ssh: continue
        _, _, code = execute_command(ssh, "java -version", ignore_errors=True)
        if code == 0: ssh.close(); continue
        if server.get('os_id') == 'ubuntu':
            execute_command(ssh, "sudo apt-get update -y && sudo apt-get install -y openjdk-11-jdk")
        elif server.get('os_id') == 'centos':
            execute_command(ssh, "sudo yum install -y java-11-openjdk-devel")
        ssh.close()
    logging.info("--- Dependency Installation Finished ---")

def distribute_kafka(servers, kafka_config):
    logging.info("--- Starting Kafka Distribution ---")
    version = kafka_config.get('version', '3.7.0')
    scala_version = "2.13"
    tgz_name = f"kafka_{scala_version}-{version}.tgz"
    local_path = f"/tmp/{tgz_name}"
    if not os.path.exists(local_path):
        urllib.request.urlretrieve(f"https://archive.apache.org/dist/kafka/{version}/{tgz_name}", local_path)
    for server in servers:
        ssh = connect_ssh(server['ip'], server['username'], server['password'])
        if not ssh: continue
        _, _, code = execute_command(ssh, "test -d /opt/kafka", ignore_errors=True)
        if code == 0: ssh.close(); continue
        sftp = ssh.open_sftp()
        sftp.put(local_path, f"/tmp/{tgz_name}")
        sftp.close()
        execute_command(ssh, f"sudo tar -xzf /tmp/{tgz_name} -C /opt")
        execute_command(ssh, f"sudo ln -s /opt/kafka_{scala_version}-{version} /opt/kafka")
        execute_command(ssh, f"sudo rm /tmp/{tgz_name}")
        ssh.close()
    logging.info("--- Kafka Distribution Finished ---")

def deploy_zookeeper(servers):
    logging.info("--- Deploying Zookeeper Ensemble ---")
    zk_props = "tickTime=2000\ndataDir=/var/lib/zookeeper\nclientPort=2181\ninitLimit=10\nsyncLimit=5\n"
    zk_props += "\n".join([f"server.{i+1}={s['ip']}:2888:3888" for i, s in enumerate(servers)])
    zk_service = "[Unit]\nDescription=Apache Zookeeper server\nRequires=network.target\nAfter=network.target\n\n[Service]\nType=simple\nUser=kafka\nGroup=kafka\nExecStart=/opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties\nExecStop=/opt/kafka/bin/zookeeper-server-stop.sh\nRestart=on-abnormal\n\n[Install]\nWantedBy=multi-user.target"
    for i, server in enumerate(servers):
        ssh = connect_ssh(server['ip'], server['username'], server['password'])
        if not ssh: continue
        execute_command(ssh, "sudo groupadd -f kafka && sudo useradd -r -g kafka -s /bin/false kafka", ignore_errors=True)
        execute_command(ssh, "sudo mkdir -p /var/lib/zookeeper")
        execute_command(ssh, f"echo '{i+1}' | sudo tee /var/lib/zookeeper/myid")
        execute_command(ssh, "sudo chown -R kafka:kafka /var/lib/zookeeper /opt/kafka*")
        upload_content(ssh, zk_props, "/tmp/zookeeper.properties")
        execute_command(ssh, "sudo mv /tmp/zookeeper.properties /opt/kafka/config/")
        upload_content(ssh, zk_service, "/tmp/zookeeper.service")
        execute_command(ssh, "sudo mv /tmp/zookeeper.service /etc/systemd/system/")
        execute_command(ssh, "sudo systemctl daemon-reload && sudo systemctl enable --now zookeeper")
        ssh.close()
    logging.info("--- Zookeeper Ensemble Deployment Finished ---")

def deploy_kafka_brokers(servers, kafka_config):
    logging.info("--- Deploying Kafka Brokers ---")
    zk_connect = ",".join([f"{s['ip']}:2181" for s in servers])
    kafka_service = "[Unit]\nDescription=Apache Kafka Server\nRequires=zookeeper.service\nAfter=zookeeper.service\n\n[Service]\nType=simple\nUser=kafka\nGroup=kafka\nExecStart=/opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties\nExecStop=/opt/kafka/bin/kafka-server-stop.sh\nRestart=on-abnormal\n\n[Install]\nWantedBy=multi-user.target"
    for i, server in enumerate(servers):
        ssh = connect_ssh(server['ip'], server['username'], server['password'])
        if not ssh: continue
        rep_factor = kafka_config.get('replication_factor', 3)
        server_props = f"broker.id={i}\nlisteners=PLAINTEXT://{server['ip']}:9092\nadvertised.listeners=PLAINTEXT://{server['ip']}:9092\nlog.dirs=/var/lib/kafka/logs\nzookeeper.connect={zk_connect}\ndefault.replication.factor={rep_factor}\nnum.partitions={kafka_config.get('partitions', 6)}\nmin.insync.replicas={max(1, rep_factor - 1)}\n"
        execute_command(ssh, "sudo mkdir -p /var/lib/kafka/logs && sudo chown -R kafka:kafka /var/lib/kafka")
        upload_content(ssh, server_props, "/tmp/server.properties")
        execute_command(ssh, "sudo mv /tmp/server.properties /opt/kafka/config/")
        upload_content(ssh, kafka_service, "/tmp/kafka.service")
        execute_command(ssh, "sudo mv /tmp/kafka.service /etc/systemd/system/")
        execute_command(ssh, "sudo systemctl daemon-reload && sudo systemctl enable --now kafka")
        ssh.close()
    logging.info("--- Kafka Broker Deployment Finished ---")

def validate_cluster(servers, kafka_config):
    """Runs post-deployment validation tests on the Kafka cluster."""
    logging.info("--- Starting Cluster Validation ---")
    if not servers: return

    primary_server = servers[0]
    bootstrap_servers = ",".join([f"{s['ip']}:9092" for s in servers])
    topic_name = "cluster-validation-topic"
    replication_factor = kafka_config.get('replication_factor', len(servers))

    ssh = connect_ssh(primary_server['ip'], primary_server['username'], primary_server['password'])
    if not ssh: logging.critical("Cannot connect to primary server for validation."); return

    try:
        # Create topic
        logging.info(f"Creating validation topic '{topic_name}'...")
        create_cmd = f"/opt/kafka/bin/kafka-topics.sh --bootstrap-server {bootstrap_servers} --create --topic {topic_name} --partitions 3 --replication-factor {replication_factor}"
        _, _, code = execute_command(ssh, create_cmd)
        if code != 0: raise Exception("Failed to create validation topic.")
        time.sleep(5)

        # Describe topic
        logging.info("Verifying topic replication...")
        describe_cmd = f"/opt/kafka/bin/kafka-topics.sh --bootstrap-server {bootstrap_servers} --describe --topic {topic_name}"
        stdout, _, _ = execute_command(ssh, describe_cmd)
        logging.info(f"Topic description:\n{stdout}")

        # Produce/Consume test
        logging.info("Running produce/consume test...")
        test_message = f"hello-kafka-{int(time.time())}"
        execute_command(ssh, f'echo "{test_message}" | /opt/kafka/bin/kafka-console-producer.sh --bootstrap-server {bootstrap_servers} --topic {topic_name}')
        consume_cmd = f"/opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server {bootstrap_servers} --topic {topic_name} --from-beginning --timeout-ms 10000"
        consumed_output, _, _ = execute_command(ssh, consume_cmd, ignore_errors=True)
        if test_message in consumed_output:
            logging.info("Cluster validation PASSED!")
        else:
            raise Exception(f"Produce/consume test FAILED. Expected '{test_message}' but got '{consumed_output}'")

    except Exception as e:
        logging.error(f"Cluster validation FAILED: {e}")
    finally:
        # Cleanup
        logging.info(f"Deleting validation topic '{topic_name}'...")
        delete_cmd = f"/opt/kafka/bin/kafka-topics.sh --bootstrap-server {bootstrap_servers} --delete --topic {topic_name}"
        execute_command(ssh, delete_cmd, ignore_errors=True)
        ssh.close()
    logging.info("--- Cluster Validation Finished ---")


def main():
    parser = argparse.ArgumentParser(description="Automated Kafka Cluster Provisioning")
    parser.add_argument('--config', type=str, required=True, help='Path to the configuration file')
    args = parser.parse_args()

    with open(args.config, 'r') as f:
        config = yaml.safe_load(f)

    servers = config.get('servers', [])
    kafka_config = config.get('kafka', {})

    run_preflight_checks(servers)
    install_dependencies(servers)
    distribute_kafka(servers, kafka_config)
    deploy_zookeeper(servers)
    deploy_kafka_brokers(servers, kafka_config)
    validate_cluster(servers, kafka_config)

    logging.info("🚀 Kafka Cluster Deployment and Validation Complete! 🚀")

if __name__ == "__main__":
    main()
