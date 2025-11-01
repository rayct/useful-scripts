## 🧩 1. `flash-parrot.sh`

Here’s a robust, safe version:

```bash
#!/usr/bin/env bash
# ======================================================
# 🐦 Parrot OS Raspberry Pi SD Card Flashing Script
# Author: rwxray
# Version: 1.0
# ======================================================

set -euo pipefail

# === Configuration (edit these) =======================
IMG="Parrot-security-6.4_rpi.img.xz"
DEVICE="/dev/mmcblk0"
HOSTNAME="parrotpi"
USERNAME="parrot"
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
```

---

### 🔧 Make it executable

```bash
chmod +x flash-parrot.sh
```

Then run:

```bash
./flash-parrot.sh
```

---

## 📘 2. `README.md`


# 🐦 Parrot OS Raspberry Pi SD Card Flashing Utility

### Author: `rwxray`
### Version: 1.0 — Updated 2025-11-01

This script automates writing the Parrot OS Raspberry Pi image to an SD card, enabling SSH, and configuring hostname and username — all in one command.

---

## ⚙️ Usage

### 1. Edit configuration
Open `flash-parrot.sh` and update:
```bash
IMG="Parrot-security-6.4_rpi.img.xz"   # Path to image
DEVICE="/dev/mmcblk0"                  # SD card device
HOSTNAME="parrotpi"                    # Desired hostname
USERNAME="parrot"                      # New username
````

### 2. Run the script

```bash
chmod +x flash-parrot.sh
./flash-parrot.sh
```

You’ll be prompted for confirmation before the SD card is overwritten.

---

## 🧩 What It Does

1. **Writes** the Parrot OS `.xz` image to the SD card using `dd`
2. **Enables SSH** by creating `/boot/ssh`
3. **Sets hostname** in `/etc/hostname` and `/etc/hosts`
4. **Renames the default user** (`user` → your chosen name)
5. **Unmounts and syncs** for a clean eject

---

🌍 Make the Script Global

If you want to run the script from anywhere (without ./), move it to a system-wide path.

### **Option 1** — Global for all users

```bash
sudo cp /home/ray/scripts/flash-sd.sh /usr/local/bin/flash-sd
sudo chmod 755 /usr/local/bin/flash-sd
```
Verify:

```bash
which flash-sd
# Output: /usr/local/bin/flash-sd
```

Now you can run:

```bash
flash-parrot
```

### **Option 2** — For your user only
```bash
mkdir -p ~/bin
cp /home/ray/scripts/flash-sd.sh ~/bin/flash-sd
chmod 755 ~/bin/flash-sd
```
Ensure `~/bin to your PATH` is in your PATH (check with `echo $PATH`).

```bash
echo 'export PATH=$PATH:~/bin' >> ~/.bashrc
source ~/.bashrc
```

> [!note] Now flash-sd works anywhere for your user only.

Then simply type:

```bash
flash-parrot
```

To verify it’s working:

```bash
which flash-parrot
```

```bash
Output should show either /usr/local/bin/flash-parrot or /home/<user>/bin/flash-parrot.
```
---

## 🧠 Notes

* SSH will be enabled on first boot.
* After boot, connect with:

  ```bash
  ssh parrot@parrotpi.local
  ```

  (Adjust username and hostname if changed.)
* If you previously ran:

  ```bash
  udisksctl power-off -b /dev/mmcblk0
  ```

  you must **reinsert or reboot** to restore power to the SD reader.

---

## 🧼 To Reset the SD Card

If you want to wipe and reformat your card:

```bash
sudo wipefs -a /dev/mmcblk0
sudo parted /dev/mmcblk0 --script mklabel msdos mkpart primary fat32 1MiB 100%
sudo mkfs.vfat -F 32 -n PARROT_SD /dev/mmcblk0p1
```

---

## ✅ Example

```bash
IMG="Parrot-security-6.4_rpi.img.xz"
DEVICE="/dev/mmcblk0"
HOSTNAME="labpi"
USERNAME="rwxray"
./flash-parrot.sh
```

After boot:

```bash
ssh rwxray@labpi.local
```

---

## 🧯 Troubleshooting

### SD Card not detected

* Reinsert card
* Check logs:

  ```bash
  sudo dmesg | tail -20
  ```
* If using `udisksctl power-off`, replug or reboot to restore power.

---

## 📦 Files

| File              | Description                          |
| ----------------- | ------------------------------------ |
| `flash-parrot.sh` | Main flashing script                 |
| `README.md`       | Documentation and usage instructions |

---

### 🧩 Credits

* Created by **rwxray**
* Inspired by hands-on Parrot ARM deployment testing
* For Raspberry Pi boards and compatible ARM SBCs

---

_**Documentation Maintained By:** Raymond C. Turner_

_**Date:** November 1st, 2025_