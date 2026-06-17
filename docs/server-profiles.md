# Server Profiles

This document describes the different server profiles that can be used to provision a server with a specific set of roles.

## Available Profiles

- **`ai-host`**: Provisions a host for running AI and machine learning workloads. This profile includes the `ollama` and `openwebui` roles.
- **`vm-host`**: Provisions a host for running virtual machines. This profile includes the `kvm` role.
- **`casaos-host`**: Provisions a host for running CasaOS. This profile includes the `casaos` role.
- **`full-lab`**: Provisions a full lab server with all available roles.

## How to Use

The server profile is determined by the Ansible playbook that is run by `ansible-pull`. You can specify the playbook to run in your `cloud-init` user data or by running `ansible-pull` manually.

### Cloud-Init

The `cloud-init/profiles` directory contains example `user-data` files for each profile. To use a profile, simply provide the corresponding file as user data to your cloud instance.

### Manual

To manually run a specific playbook, you can use the `-p` flag with `ansible-pull`:

```bash
ansible-pull -U https://github.com/your-user/homelab-base.git -p ansible/playbooks/ai-stack.yml
```

This will run the `ai-stack.yml` playbook, which configures the server as an AI host.
