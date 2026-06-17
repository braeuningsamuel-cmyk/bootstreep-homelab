# Architecture

This document outlines the architecture of the `homelab-base` repository, explaining how the different components work together to create a fully automated and idempotent server provisioning system.

## Core Components

The system is built around a few core components:

- **cloud-init**: Used for the initial provisioning of the server on first boot. It sets up a user, installs Ansible, and triggers the `ansible-pull` process.
- **ansible-pull**: A version of Ansible that pulls playbooks from a Git repository and executes them on the local machine. This allows for a decentralized, "pull-based" configuration management approach.
- **Ansible Roles**: The configuration is broken down into modular Ansible roles, making it easy to manage and extend.
- **Docker Compose**: Used to define and run multi-container Docker applications.
- **KVM/libvirt**: Provides a full virtualization solution for running virtual machines.

## Provisioning Flow

The provisioning process is designed to be fully automated:

1.  **First Boot**: On the first boot of a new Ubuntu Server instance, `cloud-init` is executed.
2.  **User and SSH Setup**: `cloud-init` creates a new user and adds your public SSH key for remote access.
3.  **Ansible Installation**: `cloud-init` installs Ansible on the system.
4.  **Repository Cloning**: The `homelab-base` repository is cloned to `/opt/homelab-base`.
5.  **Ansible-Pull Execution**: `ansible-pull` is executed, which runs the main `site.yml` playbook.
6.  **System Configuration**: The Ansible playbook applies the various roles to configure the system according to the defined host profiles.

This process ensures that a new server can be fully provisioned and configured without any manual intervention.
