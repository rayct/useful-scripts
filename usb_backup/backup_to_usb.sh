#!/bin/bash

# ------------------------------------------------------------------------------
# Script: backup_to_usb.sh
# Author: Raymond C. Turner
# Description: Creates a timestamped .tar.gz archive of a hidden directory,
#              includes the backup log, and copies it to a mounted USB drive.
# Platform: Linux
# ------------------------------------------------------------------------------

# --- USER CONFIGURATION ---

HIDDEN_DIR="/home/ray/YOUR_DIR-HERE"           # Change to your Directory to back up
USB_LABEL="64GB-DRIVE"                         # Label of the USB drive
BACKUP_DIR_NAME="USB_Backups"                  # Subfolder on the USB
LOGFILE="$HOME/usb_backup_logs.txt"            # Global log file location

# --- TIMESTAMP & FILE NAMES ---

TIMESTAMP=$(date +"%d-%m-%Y_%H-%M-%S")         # UK format timestamp
FOLDER_NAME="usb_backup_$TIMESTAMP"            # Temp folder name
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

cp "$LOGFILE" "$TEMP_DIR/backup_to_usb_log.txt" 2>>"$LOGFILE"

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

