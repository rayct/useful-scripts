Your markdown is already excellent — it’s clearly structured, consistent, and professional.
Below is a **proofread and lightly optimized version** with only minor improvements for clarity, grammar, and consistency (no technical content altered).

---

# 🐦 Parrot OS Raspberry Pi SD Card Flashing Utility

### Author: `rwxray`

### Version: 1.3 — Updated 2025-11-02

This script automates writing the Parrot OS Raspberry Pi image to an SD card, enabling SSH, and configuring the hostname and username — all in one command.
Version 1.3 is robust against read-only boot partitions and single-partition images.

---

## ⚙️ Usage

### 1. Edit Configuration

Open `flash-sd_v1.3` and update:

```bash
IMG="Parrot-security-6.4_rpi.img.xz"   # Path to image
DEVICE="/dev/mmcblk0"                  # SD card device
HOSTNAME="parrotpi"                    # Desired hostname
USERNAME="parrot"                      # New username
```

---

### 2. Run the Script

If you’re still in your scripts directory:

```bash
chmod +x flash-sd_v1.3
./flash-sd_v1.3
```

You’ll be prompted for confirmation before the SD card is overwritten.

---

## 🌍 Make the Script Global

### Option 1 — System-wide (all users)

```bash
chmod +x flash-sd_v1.3.sh
sudo cp flash-sd_v1.3.sh /usr/local/bin/flash-sd
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
2. **Automatically remounts the boot partition read-write** to reliably create the `ssh` file.
3. Detects partition layout — works with both **single-partition and multi-partition images**.
4. Sets the hostname and renames the default user only if the root partition can be mounted.
5. Unmounts and syncs the SD card for a clean, safe eject.

---

## ⚠️ Notes for v1.3

* If the **boot partition is read-only**, the script remounts it read-write for SSH.

* If the **root partition cannot be mounted**, hostname and user changes are skipped — this is normal for some Parrot RPi images.

* SSH is enabled automatically on the first boot.

* Some images expand the filesystem automatically on first boot; do **not attempt a manual resize**.

* After the first boot, connect via:

  ```bash
  ssh parrot@parrotpi.local
  ```

  (Adjust the username and hostname if you’ve changed them.)

* If you previously ran:

  ```bash
  udisksctl power-off -b /dev/mmcblk0
  ```

  you must **reinsert the SD card or reboot** to restore power to the SD reader.

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

### SD Card Not Detected

* Reinsert the card.
* Check logs with:

  ```bash
  sudo dmesg | tail -20
  ```
* If you used `udisksctl power-off`, replug or reboot to restore power.
* **Read-only boot partition:** Script v1.3 remounts automatically; however, SSH may still fail if the base image enforces a read-only boot.

---

## 📦 Files

| File            | Description                         |
| --------------- | ----------------------------------- |
| `flash-sd_v1.3` | Main flashing script (global-ready) |
| `README.md`     | Documentation and usage guide       |

---

### 🧩 Credits

* Created by **rwxray**
* Designed for Raspberry Pi boards and compatible ARM SBCs
* Inspired by hands-on Parrot ARM deployment testing
* Compatible with both **single-partition and multi-partition Parrot RPi images**

---

***Documentation Maintained By:** Raymond C. Turner*
***Date:** November 2, 2025*

---

✅ **Summary of Edits:**

* Improved sentence flow and readability.
* Standardized phrasing (“if the root partition cannot be mounted,” etc.).
* Simplified “do not attempt manual resize” to avoid redundancy.
* Fixed a few small markdown spacing inconsistencies.
* Added commas and colons for clarity in instructional text.

Would you like me to output this as a ready-to-save `README.md` file (UTF-8 Markdown)?
