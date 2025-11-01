#!/usr/bin/env bash
# ======================================================
# 🐦 Parrot OS Raspberry Pi SD Card Flashing Script
# Name: flash-sd
# Author: rwxray
# Version: 1.2
# ======================================================

set -euo pipefail

# === Configuration (edit these) =======================
# IMG="Parrot-security-6.4_rpi.img.xz"
IMG="Parrot-home-6.4_rpi.img.xz"
DEVICE="/dev/mmcblk0"
HOSTNAME="eMMA"
USERNAME="rwxray"
# ======================================================

echo "🚀 Starting Parrot OS flash process (flash-sd)..."
echo "Image:    $IMG"
echo "Device:   $DEVICE"
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

# --- Step 2: Detect partitions ---
echo "🔍 Detecting partitions..."
PARTS=($(lsblk -ln -o NAME "$DEVICE" | grep -v "^$(basename $DEVICE)$"))
NUM_PARTS=${#PARTS[@]}
echo "Found $NUM_PARTS partition(s): ${PARTS[*]}"

# --- Step 3: Mount partitions ---
BOOT_MOUNT=""
ROOT_MOUNT=""
sudo mkdir -p /mnt/flash-sd-boot /mnt/flash-sd-root

if [ "$NUM_PARTS" -eq 0 ]; then
    # Single-partition image (full disk)
    echo "⚠️ No separate partitions detected — mounting $DEVICE directly as root."
    sudo mount "$DEVICE" /mnt/flash-sd-root
    ROOT_MOUNT="/mnt/flash-sd-root"
else
    # Multi-partition image
    BOOT_DEV="/dev/${PARTS[0]}"
    ROOT_DEV="/dev/${PARTS[1]:-${PARTS[0]}}"
    echo "Mounting boot: $BOOT_DEV -> /mnt/flash-sd-boot"
    sudo mount -o rw "$BOOT_DEV" /mnt/flash-sd-boot
    BOOT_MOUNT="/mnt/flash-sd-boot"

    echo "Mounting root: $ROOT_DEV -> /mnt/flash-sd-root"
    sudo mount "$ROOT_DEV" /mnt/flash-sd-root || echo "⚠️ Could not mount root partition, skipping root customization."
    ROOT_MOUNT="/mnt/flash-sd-root"
fi

# --- Step 4: Enable SSH ---
if [ -n "$BOOT_MOUNT" ]; then
    echo "🔑 Enabling SSH on boot partition..."
    sudo touch "$BOOT_MOUNT/ssh"
elif [ -n "$ROOT_MOUNT" ]; then
    echo "🔑 Enabling SSH in root partition..."
    sudo touch "$ROOT_MOUNT/ssh"
fi

# --- Step 5: Set hostname & change default user ---
if [ -n "$ROOT_MOUNT" ]; then
    if [ -f "$ROOT_MOUNT/etc/hostname" ]; then
        echo "🧭 Setting hostname to '$HOSTNAME'..."
        echo "$HOSTNAME" | sudo tee "$ROOT_MOUNT/etc/hostname" >/dev/null
        sudo sed -i "s/^127\.0\.1\.1.*/127.0.1.1\t$HOSTNAME/" "$ROOT_MOUNT/etc/hosts"
    fi

    DEFAULT_USER="user"
    if sudo chroot "$ROOT_MOUNT" id "$DEFAULT_USER" &>/dev/null; then
        echo "👤 Renaming default user '$DEFAULT_USER' → '$USERNAME'..."
        sudo chroot "$ROOT_MOUNT" usermod -l "$USERNAME" "$DEFAULT_USER"
        sudo chroot "$ROOT_MOUNT" groupmod -n "$USERNAME" "$DEFAULT_USER"
    else
        echo "⚠️  Default user '$DEFAULT_USER' not found, skipping rename."
    fi
fi

# --- Step 6: Cleanup ---
echo "🧹 Unmounting and syncing..."
[ -n "$BOOT_MOUNT" ] && sudo umount "$BOOT_MOUNT" || true
[ -n "$ROOT_MOUNT" ] && sudo umount "$ROOT_MOUNT" || true
sync

echo "✅ All done!"
echo "🔌 It is now safe to remove the SD card."
echo "You can SSH after first boot: ssh ${USERNAME}@${HOSTNAME}.local"
