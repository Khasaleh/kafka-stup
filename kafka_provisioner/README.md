# Automated Kafka Cluster Provisioning

This script automates the provisioning of a horizontally scalable Kafka cluster in High Availability (HA) mode.

## Prerequisites

- Python 3.6+
- Access to target servers with username/password credentials.

## Usage

1. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure your servers:**
   - Edit the `servers.yaml` file to match your server details (IP, username, password) and desired Kafka configuration.

3. **Run the deployment script:**
   ```bash
   python deploy_kafka.py --config servers.yaml
   ```

## Project Structure

- `deploy_kafka.py`: The main deployment script.
- `servers.yaml`: Configuration file for servers and Kafka settings.
- `requirements.txt`: Python dependencies.
- `README.md`: This file.
