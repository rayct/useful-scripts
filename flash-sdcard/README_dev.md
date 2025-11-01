# 🐦 Parrot OS Raspberry Pi SD Card Flashing Utility

### Author: `rwxray`
### Version: 1.3 — Updated 2025-11-01

This script automates writing the Parrot OS Raspberry Pi image to an SD card, enabling SSH, and handling hostname/username configuration — all in one command.
v1.3 is robust against read-only boot partitions and single-partition images.

---

## ⚙️ Usage

### 1. Edit configuration
Open `flash-sd_v1.3` and update:

```bash
IMG="Parrot-security-6.4_rpi.img.xz"   # Path to image
DEVICE="/dev/mmcblk0"                  # SD card device
HOSTNAME="parrotpi"                    # Desired hostname
USERNAME="parrot"                      # New username
```

---

### 2. Run the script

If still in your scripts directory:

```bash
chmod +x flash-sd_v1.3
./flash-sd_v1.3
```

You’ll be prompted for confirmation before the SD card is overwritten.

---

## 🌍 Make the Script Global

### Option 1 — System-wide (all users)

```bash
sudo cp flash-sd_v1.3 /usr/local/bin/flash-sd
sudo chmod 755 /usr/local/bin/flash-sd
```

Now you can run it from **any directory**:

```bash
flash-sd
```

Verify:

```bash
which flash-sd
# Output: /usr/local/bin/flash-sd
```

---

### Option 2 — User-only

```bash
mkdir -p ~/bin
cp flash-sd_v1.3 ~/bin/flash-sd
chmod 755 ~/bin/flash-sd
```

Add `~/bin` to your PATH:

```bash
echo 'export PATH=$PATH:~/bin' >> ~/.bashrc
source ~/.bashrc
```

Now `flash-sd` works anywhere for your user only.

---

## 🧩 What It Does

1. Writes the Parrot OS `.xz` image to the SD card using `dd`.
2. **Automatically remounts boot partition read-write** to reliably create the `ssh` file.
3. Detects partition layout; works with **single-partition or multi-partition images**.
4. Attempts to set hostname and rename default user only if the root partition can be mounted.
5. Unmounts and syncs for a clean eject.

---

## ⚠️ Notes for v1.3

* If the **boot partition is read-only**, the script remounts it read-write for SSH.
* If the **root partition cannot mount**, hostname/user changes are skipped; this is normal for some Parrot RPi images.
* SSH may still be enabled on boot even if the root partition isn’t writable.
* Some images automatically expand the filesystem on first boot; do **not attempt manual resize**.

---

## 🧼 To Reset the SD Card

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
flash-sd
```

After first boot:

```bash
ssh rwxray@labpi.local
```

---

## 🧯 Troubleshooting

* **SD Card not detected**: Reinsert card, check logs with `sudo dmesg | tail -20`.
* **udisksctl power-off**: Replug or reboot to restore SD reader power.
* **Read-only boot partition**: script v1.3 remounts automatically; SSH may still fail if the underlying image enforces read-only.

---

## 📦 Files

| File            | Description                          |
| --------------- | ------------------------------------ |
| `flash-sd_v1.3` | Main flashing script (global-ready)  |
| `README.md`     | Documentation and usage instructions |

---

### 🧩 Credits

* Created by **rwxray**
* Designed for Raspberry Pi boards and compatible ARM SBCs
* Inspired by hands-on Parrot ARM deployment testing
* Compatible with **single-partition and multi-partition Parrot RPi images**

---

_**Documentation Maintained By:** Raymond C. Turner_

_**Date:** November 2nd, 2025_