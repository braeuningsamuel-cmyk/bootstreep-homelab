# Cloud-Init Flow

## Übersicht

Cloud-Init ermöglicht die vollautomatische Einrichtung eines Servers
beim ersten Boot. Kein manuelles Login erforderlich.

## Voraussetzungen

- Ubuntu Server 24.04 LTS ISO
- Hypervisor mit cloud-init Support (Proxmox, libvirt, VMware, etc.)
- Fork des Repos (optional, für eigene Anpassungen)

## Vorbereitung

### 1. `cloud-init/user-data.example` anpassen

```yaml
#cloud-config
users:
  - name: admin                           # ← Dein Benutzername
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3... dein-key    # ← Dein Public SSH-Key

runcmd:
  - git clone https://github.com/...
  - cd /opt/bootstreep-homelab && ./bootstrap.sh
```

### 2. ISO erstellen (für manuelle Installation)

Falls der Hypervisor kein cloud-init direkt unterstützt:

```bash
# cloud-init ISO erstellen
mkdir -p cloud-init-files
cp cloud-init/user-data.example cloud-init-files/user-data
# meta-data ist optional
cat > cloud-init-files/meta-data <<EOF
instance-id: homelab-1
local-hostname: homelab-server
EOF

# ISO generieren
genisoimage -output seed.iso -volid cidata -joliet -rock \
  cloud-init-files/user-data cloud-init-files/meta-data
```

Diese `seed.iso` wird der VM als CD-ROM hinzugefügt.

### 3. VM erstellen

**Proxmox:**
```bash
qm create 100 --name homelab --memory 32768 --cores 8 \
  --net0 virtio,bridge=vmbr0
qm set 100 --scsi0 local-lvm:100
qm set 100 --ide2 local:iso/ubuntu-24.04-live-server-amd64.iso,media=cdrom
qm set 100 --ide3 local:iso/seed.iso,media=cdrom
qm start 100
```

**libvirt/KVM:**
```bash
virt-install --name homelab --memory 32768 --vcpus 8 \
  --disk size=100 --cdrom ubuntu-24.04.iso \
  --disk seed.iso,device=cdrom \
  --os-variant ubuntu24.04
```

## Ablauf beim ersten Boot

```
1. VM startet
2. Ubuntu-Installer erkennt cloud-init
3. cloud-init liest user-data von CD-ROM
4. Benutzer wird angelegt, SSH-Key hinterlegt
5. Repository wird geklont
6. bootstrap.sh wird ausgeführt
7. Nach ~30–60 Min: Homelab fertig eingerichtet
```

## Profile

Für spezifische Anwendungsfälle können angepasste Profile erstellt werden.
Die `cloud-init/` Struktur unterstützt verschiedene Setups:

| Profil | Beschreibung |
|---|---|
| `user-data.example` | Volles Homelab (Standard) |
| (erweiterbar) | Geplante Profile für AI-only, Media-only etc. |
