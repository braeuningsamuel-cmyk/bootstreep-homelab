# Cloud-Init Flow

This document explains how `cloud-init` is used to automate the initial provisioning of a new server.

## User Data

The `cloud-init/user-data.example` file is the main configuration file for `cloud-init`. It is provided to the cloud instance as "user data" during creation.

### Key Sections

- **`users`**: This section creates a new user, grants them `sudo` privileges, and adds a public SSH key for remote access.
- **`package_update` and `package_upgrade`**: These directives ensure that the system's package list is updated and all packages are upgraded to their latest versions.
- **`packages`**: This section installs the necessary packages for the bootstrap process, including `git`, `curl`, and `ansible`.
- **`runcmd`**: This is a list of commands that are executed on the first boot. In this case, it clones the `homelab-base` repository and then executes the `first-boot.sh` script.

## Ansible Integration

`cloud-init` also has built-in support for Ansible. The `cloud-init/profiles` directory contains examples of how to use this feature.

### How it Works

Instead of using `runcmd` to manually clone the repository and run `ansible-pull`, you can use the `ansible` directive in your `user-data` file. This tells `cloud-init` to install Ansible and then run `ansible-pull` with the specified repository and playbook.

This is a more streamlined approach, but the `runcmd` method is also provided for greater flexibility.
