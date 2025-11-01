#!/usr/bin/env bash
# ======================================================
# 🐦 Parrot OS Raspberry Pi SD Card Flashing Script
# Author: rwxray
# Version: 1.0
# ======================================================

set -euo pipefail

# === Configuration (edit these) =======================
IMG="Parrot-home-6.4_rpi.img.xz"
# IMG="Parrot-security-6.4_rpi.img.xz"
DEVICE="/dev/mmcblk0"
HOSTNAME="rwxray"
USERNAME="eMMa"
# ======================================================

echo "🚀 Starting Parrot OS flash process..."
echo "Image:   $IMG"
echo "Device:  $DEVICE"
echo "Hostname: $HOSTNAME"
echo "Username: $USERNAME"
echo

read -rp "⚠️  This will ERASE all data on $DEVICE. Continue? (y/N): " CONFIRM
[[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }

# --- Step 1: Write image ---
echo "📝 Writing image to $DEVICE..."
xz -dc "$IMG" | sudo dd of="$DEVICE" bs=4M conv=fsync status=progress
sync
echo "✅ Image write complete."

# --- Step 2: Mount partitions ---
echo "🔍 Mounting partitions..."
sudo partprobe "$DEVICE"
BOOT="${DEVICE}p1"
ROOT="${DEVICE}p2"

sudo mkdir -p /mnt/parrot-boot /mnt/parrot-root
sudo mount "$BOOT" /mnt/parrot-boot
sudo mount "$ROOT" /mnt/parrot-root

# --- Step 3: Enable SSH ---
echo "🔑 Enabling SSH..."
sudo touch /mnt/parrot-boot/ssh

# --- Step 4: Set hostname ---
echo "🧭 Setting hostname to '$HOSTNAME'..."
echo "$HOSTNAME" | sudo tee /mnt/parrot-root/etc/hostname >/dev/null
sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$HOSTNAME/" /mnt/parrot-root/etc/hosts

# --- Step 5: Change default user ---
DEFAULT_USER="user"
if sudo chroot /mnt/parrot-root id "$DEFAULT_USER" &>/dev/null; then
  echo "👤 Renaming default user '$DEFAULT_USER' → '$USERNAME'..."
  sudo chroot /mnt/parrot-root usermod -l "$USERNAME" "$DEFAULT_USER"
  sudo chroot /mnt/parrot-root groupmod -n "$USERNAME" "$DEFAULT_USER"
else
  echo "⚠️  Default user '$DEFAULT_USER' not found, skipping rename."
fi

# --- Step 6: Cleanup ---
echo "🧹 Unmounting and syncing..."
sudo umount /mnt/parrot-boot || true
sudo umount /mnt/parrot-root || true
sync

echo "✅ All done!"
echo "🔌 It is now safe to remove the SD card."
echo "You can SSH after first boot: ssh ${USERNAME}@${HOSTNAME}.local"
