# Windows 11 VM Setup

This document provides instructions for setting up a Windows 11 virtual machine using KVM/libvirt.

## Prerequisites

- A host system with KVM and libvirt installed and running.
- A Windows 11 ISO image.

## Creating the VM

The `scripts/create-win11-vm.sh` script is provided to automate the creation of the VM.

### Configuration

Before running the script, you can customize the VM's settings by editing the `libvirt/vm/win11-vars.example.yml` file. This file allows you to specify the VM's name, vCPU count, memory, and disk size.

### Usage

To create the VM, simply run the following command:

```bash
./scripts/create-win11-vm.sh
```

This will create a new VM with the specified settings and start the Windows 11 installation process.

## XML Template

The `libvirt/vm/windows11.xml` file is a libvirt XML template for the Windows 11 VM. This file can be used to manually create the VM using `virsh`:

```bash
virsh define libvirt/vm/windows11.xml
```

This provides an alternative to using the `create-win11-vm.sh` script.
