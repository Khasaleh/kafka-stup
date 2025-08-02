# Password-Based Authentication Guide

This document provides a guide on how to set up and use password-based authentication for this project.

## 1. `microk8s_ansible_deploy`

This project uses Ansible to deploy the MicroK8s cluster and applications. The SSH password can be provided in the `ansible.cfg` file or passed on the command line.

### a. Configure the Password in `ansible.cfg`

You can add the `ansible_password` variable to the `[defaults]` section of the `ansible.cfg` file:

**`ansible.cfg`:**
```ini
[defaults]
inventory = hosts
private_key_file = ssh/id_rsa
ansible_password = "YOUR_PASSWORD_HERE"
```

### b. Pass the Password on the Command Line

You can also pass the password on the command line using the `--ask-pass` flag:

```bash
ansible-playbook -i hosts install-cluster.yml --ask-pass
```

## 2. `kafka_provisioner`

The `kafka_provisioner` script uses password-based authentication to connect to the target servers. The password for each server is defined in the `kafka_provisioner/servers.yaml` file.

**`kafka_provisioner/servers.yaml`:**
```yaml
servers:
  - ip: 192.168.1.201
    username: root
    password: "YOUR_PASSWORD_HERE"
  - ip: 192.168.1.202
    username: root
    password: "YOUR_PASSWORD_HERE"
  - ip: 192.168.1.203
    username: root
    password: "YOUR_PASSWORD_HERE"
```

## 3. `eureka_deploy`

The `eureka_deploy` project uses Ansible to deploy the Eureka server cluster. The SSH password can be provided in the `eureka_deploy/ansible/hosts` file.

**`eureka_deploy/ansible/hosts`:**
```ini
[all:vars]
ansible_user=root
ansible_password="YOUR_PASSWORD_HERE"
```
