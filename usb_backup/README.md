## ✅ `backup_to_usb.sh` (with comments)

```bash
#!/bin/bash

# ------------------------------------------------------------------------------
# Script: backup_to_usb.sh
# Author: Your Name
# Description: Creates a timestamped .tar.gz archive of a hidden directory,
#              includes the backup log, and copies it to a mounted USB drive.
# Platform: Linux
# ------------------------------------------------------------------------------

# --- USER CONFIGURATION ---

HIDDEN_DIR="/home/ray/._Learning"              # Directory to back up
USB_LABEL="64GB-DRIVE"                          # Label of the USB drive
BACKUP_DIR_NAME="Learning_Backups"             # Subfolder on the USB
LOGFILE="$HOME/backup_logs.txt"                # Global log file location

# --- TIMESTAMP & FILE NAMES ---

TIMESTAMP=$(date +"%d-%m-%Y_%H-%M-%S")          # UK format timestamp
FOLDER_NAME="learning_backup_$TIMESTAMP"       # Temp folder name
ARCHIVE_NAME="$FOLDER_NAME.tar.gz"             # Final archive name
TEMP_PARENT="/tmp"                             # Staging parent directory
TEMP_DIR="$TEMP_PARENT/$FOLDER_NAME"           # Full staging folder path
TEMP_ARCHIVE="$TEMP_PARENT/$ARCHIVE_NAME"      # Path to the temporary archive

# --- DETECT USB MOUNT POINT BY LABEL ---

USB_MOUNT=$(lsblk -o LABEL,MOUNTPOINT | grep "$USB_LABEL" | awk '{print $2}')

if [ -z "$USB_MOUNT" ]; then
  echo "[$(date)] ❌ USB drive '$USB_LABEL' not mounted." | tee -a "$LOGFILE"
  exit 1
fi

DEST_DIR="$USB_MOUNT/$BACKUP_DIR_NAME"

# --- CREATE STAGING DIRECTORY ---

echo "[$(date)] 📂 Creating staging directory: $TEMP_DIR" | tee -a "$LOGFILE"
mkdir -p "$TEMP_DIR"

# --- COPY FILES TO STAGING AREA ---

cp -a "$HIDDEN_DIR/" "$TEMP_DIR/" 2>>"$LOGFILE"

# --- INCLUDE LOG FILE IN BACKUP ---

cp "$LOGFILE" "$TEMP_DIR/backup_log.txt" 2>>"$LOGFILE"

# --- CREATE ARCHIVE ---

echo "[$(date)] 📦 Creating archive: $TEMP_ARCHIVE" | tee -a "$LOGFILE"
tar -czf "$TEMP_ARCHIVE" -C "$TEMP_PARENT" "$FOLDER_NAME" 2>>"$LOGFILE"

# --- COPY ARCHIVE TO USB ---

echo "[$(date)] 💾 Copying archive to: $DEST_DIR" | tee -a "$LOGFILE"
mkdir -p "$DEST_DIR"
cp "$TEMP_ARCHIVE" "$DEST_DIR/"

# --- CLEAN UP ---

rm -rf "$TEMP_DIR" "$TEMP_ARCHIVE"

# --- LOG SUCCESSFUL BACKUP ---

echo "[$(date)] ✅ Backup complete. Archive saved as: $DEST_DIR/$ARCHIVE_NAME" | tee -a "$LOGFILE"
echo "" >> "$LOGFILE"
```

---

## ✅ `README.md`

```markdown
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

```

learning\_backup\_01-07-2025\_18-15-22.tar.gz
└── learning\_backup\_01-07-2025\_18-15-22/
├── notes.md
├── diagrams/
└── backup\_log.txt

````

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
````

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

