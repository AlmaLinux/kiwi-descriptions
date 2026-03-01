#!/bin/bash
set -euo pipefail

for cmd in genisoimage virt-install virsh; do
  command -v "$cmd" &>/dev/null || { echo "Error: $cmd not found"; exit 1; }
done

QCOW2="${1:?Usage: $0 <image.qcow2>}"
VM_NAME="test-$(date +%s)"
WORK_DIR=$(mktemp -d)

cleanup() {
  virsh destroy "$VM_NAME" 2>/dev/null || true
  virsh undefine "$VM_NAME" --nvram 2>/dev/null || true
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

chmod 711 "$WORK_DIR"
cp "$QCOW2" "$WORK_DIR/disk.qcow2"

cat > "$WORK_DIR/meta-data" <<EOF
instance-id: $VM_NAME
local-hostname: $VM_NAME
EOF

cat > "$WORK_DIR/user-data" <<EOF
#cloud-config
password: almalinux
chpasswd:
  expire: false
ssh_pwauth: true
EOF

genisoimage -output "$WORK_DIR/cidata.iso" -volid cidata -joliet -rock \
  "$WORK_DIR/user-data" "$WORK_DIR/meta-data"

virt-install \
  --name "$VM_NAME" \
  --memory 2048 \
  --vcpus 2 \
  --import \
  --disk "path=$WORK_DIR/disk.qcow2,format=qcow2" \
  --disk "path=$WORK_DIR/cidata.iso,device=cdrom" \
  --os-variant almalinux10 \
  --graphics none \
  --serial pty \
  --console pty,target_type=serial \
  --noautoconsole

echo "VM '$VM_NAME' started. Connecting to console..."
echo "  (Use Ctrl+] to detach)"
echo "  Login: almalinux / almalinux"
echo ""
virsh console "$VM_NAME"
