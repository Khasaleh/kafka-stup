# SSH Key-Based Authentication Guide

This document provides a guide on how to set up and use SSH key-based authentication for this project. This method is more secure and convenient than using passwords.

## Why Use SSH Keys?

-   **Security:** SSH keys are much more difficult to brute-force than passwords.
-   **Convenience:** Once you have set up SSH key-based authentication, you can log in to your servers without having to enter a password every time.
-   **Automation:** SSH keys are essential for automated deployments, as they allow your scripts to connect to your servers without any manual intervention.

## 1. Generate an SSH Key

An SSH key pair has been generated for you and is located in the `ansible/ssh` directory:

-   `ansible/ssh/id_rsa`: The private key. **This file should be kept secret and should not be shared.**
-   `ansible/ssh/id_rsa.pub`: The public key. This file can be safely shared.

## 2. Distribute the Public Key

To enable SSH key-based authentication, you need to copy the contents of the public key (`ansible/ssh/id_rsa.pub`) to the `~/.ssh/authorized_keys` file on each of your target servers (masters and workers).

You can do this manually or by using the `ssh-copy-id` command:

```bash
ssh-copy-id -i ansible/ssh/id_rsa.pub <user>@<server-ip>
```

Replace `<user>` with your username and `<server-ip>` with the IP address of your server. You will be prompted for your password one last time.

## 3. Configure Ansible to Use the SSH Key

The Ansible playbooks in this project are configured to use the private key in the `ansible/ssh` directory. The `ansible.cfg` file should be updated to point to the private key file.

**`ansible.cfg`:**
```ini
[defaults]
inventory = hosts
private_key_file = ssh/id_rsa
```

This configuration tells Ansible to use the `ssh/id_rsa` private key for all SSH connections.

## 4. Configure the `kafka_provisioner`

The `kafka_provisioner` script has been updated to use SSH key-based authentication. You no longer need to specify a password in the `servers.yaml` file.

**`servers.yaml`:**
```yaml
servers:
  - ip: 192.168.1.225
    username: your_user
  - ip: 192.168.1.226
    username: your_user
  - ip: 192.168.1.227
    username: your_user
```

The script will now use the private key specified in your SSH agent or the default location (`~/.ssh/id_rsa`). To use the key generated for this project, you can add it to your SSH agent:

```bash
ssh-add ansible/ssh/id_rsa
```
