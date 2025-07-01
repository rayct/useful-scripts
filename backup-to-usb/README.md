## ✅ `Backup to USB README.md`


# 📦 Directory USB Backup Script

A Bash script to securely back up a hidden directory (`._Learning`) to a USB drive by creating timestamped `.tar.gz` archives. Each archive includes the backup log for traceability and reproducibility.

---

## 🔧 Features

- 🗂️ Backs up `/home/ray/YOUR_DIR_HERE`
- 💾 Saves to a mounted USB by label (e.g., `64GB-DRIVE`)
- 📦 Compresses everything into a single `.tar.gz` archive
- 🧠 Includes a copy of the log file in every backup
- ⏱️  Appends a UK-format timestamp to each archive to prevent overwriting
- 🧹 Cleans up temp files after completion

---

## 📂 Archive Example

learning\_backup\_01-07-2025\_18-15-22.tar.gz
└── learning\_backup\_01-07-2025\_18-15-22/
├── notes.md
├── diagrams/
└── backup\_log.txt

---

## 🛠️ Requirements

- Linux system
- Mounted USB drive with a known volume label (default: `64GB-DRIVE`)
- `tar`, `lsblk`, `awk`, `cp`, `mkdir`, and `tee` installed

---

## 🚀 Usage

1. **Edit the script** to match your setup:
   - Update the `HIDDEN_DIR` path
   - Update your USB `LABEL`

2. **Make the script executable:**
   ```bash
   chmod +x backup_to_usb.sh
```

3. **Run the script (with sudo if needed for USB access):**

   ```bash
   sudo ./backup_to_usb.sh
   ```

---

## 📒 Notes

* You can schedule this with `cron` for automatic backups
* Archives are safe to store on exFAT/FAT32 formatted USB drives
* Works even if the hidden directory contains symbolic links (they're preserved inside the archive)

---

## 🔐 Optional Add-ons

* Encrypt the archive using `gpg` or `openssl`
* Sync backups to cloud (rclone, rsync, etc.)
* Trigger automatically on USB insert using `udev` rules

---

## 📄 License

MIT — free for personal or commercial use


