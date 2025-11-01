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