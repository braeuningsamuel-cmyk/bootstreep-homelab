#!/bin/bash
#
# create-win11-vm.sh: Creates a Windows 11 VM using virt-install.
#

set -e

# Load variables from config file
if [ -f "libvirt/vm/win11-vars.yml" ]; then
   VM_NAME=$(grep vm_name libvirt/vm/win11-vars.example.yml | cut -d ":" -f2 | tr -d " ")
VCPU=$(grep vcpu libvirt/vm/win11-vars.example.yml | cut -d ":" -f2 | tr -d " ")
MEMORY_MB=$(grep memory_mb libvirt/vm/win11-vars.example.yml | cut -d ":" -f2 | tr -d " ")
DISK_SIZE_GB=$(grep disk_size_gb libvirt/vm/win11-vars.example.yml | cut -d ":" -f2 | tr -d " ")
ISO_PATH=$(grep iso_path libvirt/vm/win11-vars.example.yml | cut -d ":" -f2 | tr -d " ")
fi

# Default values
VM_NAME=${vm_name:-windows11}
VCPU=${vcpu:-4}
MEMORY_MB=${memory_mb:-8192}
DISK_SIZE_GB=${disk_size_gb:-100}
ISO_PATH=${iso_path:-/var/lib/libvirt/images/win11.iso}

virt-install \
    --name $VM_NAME \
    --vcpus $VCPU \
    --memory $MEMORY_MB \
    --disk path=/var/lib/libvirt/images/$VM_NAME.qcow2,size=$DISK_SIZE_GB,bus=virtio,format=qcow2 \
    --os-variant win11 \
    --cdrom $ISO_PATH \
    --network network=default,model=virtio \
    --graphics spice \
    --boot uefi

echo "VM $VM_NAME created successfully."
