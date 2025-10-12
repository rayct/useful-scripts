# FileZilla repair script, now with proper YAML frontmatter for categorization, searchability, and tags.

---
title: Fix FileZilla Queue Script
author: rwxray
created: 2025-10-11
updated: 2025-10-11
tags:
  - linux
  - filezilla
  - script
  - troubleshooting
  - sqlite
category: scripts
aliases:
  - filezilla queue fix
  - reset filezilla queue
description: >
  A Bash script to reset and clean FileZilla’s transfer queue database, fix file permissions,
  and remove stale SQLite journals to resolve queue loading/saving errors.
---

# 🧹 Fix FileZilla Queue Script

## Overview
If FileZilla shows errors like:

> **An error occurred saving or loading the transfer queue from `~/.config/filezilla/queue.sqlite3`**

…it usually means the transfer queue database is corrupted or locked.  
This script safely resets the queue, fixes permissions, and removes stale SQLite journal files — allowing FileZilla to start fresh.

---

## 🛠️ Script: `fix-filezilla-queue.sh`

```bash
#!/usr/bin/env bash
#
# fix-filezilla-queue.sh
# -----------------------
# Safely reset and clean FileZilla’s transfer queue database.
# Intended for Linux systems where FileZilla stores its config under ~/.config/filezilla/
#
# Author: rwxray
# Created: 2025-10-11
# Version: 1.0
#
# Usage:
#   ./fix-filezilla-queue.sh
#
# Optional:
#   Install globally (requires sudo):
#     sudo install -m 755 fix-filezilla-queue.sh /usr/local/bin/fix-filezilla-queue
#
# Then run anytime:
#     fix-filezilla-queue
#

set -euo pipefail

QUEUE_DIR="$HOME/.config/filezilla"
QUEUE_FILE="$QUEUE_DIR/queue.sqlite3"

echo "🔧 Checking FileZilla queue at: $QUEUE_FILE"

# Ensure the directory exists
if [[ ! -d "$QUEUE_DIR" ]]; then
  echo "Creating FileZilla config directory..."
  mkdir -p "$QUEUE_DIR"
fi

# Remove any leftover SQLite journal or lock files
echo "🧹 Removing stale SQLite journal files..."
rm -f "$QUEUE_DIR"/queue.sqlite3-{wal,shm,journal} 2>/dev/null || true

# Backup old queue file if it exists
if [[ -f "$QUEUE_FILE" ]]; then
  BACKUP_FILE="$QUEUE_FILE.bak.$(date +%Y%m%d%H%M%S)"
  echo "📦 Backing up old queue file to: $BACKUP_FILE"
  mv -f "$QUEUE_FILE" "$BACKUP_FILE"
else
  echo "ℹ️ No existing queue file found — starting fresh."
fi

# Create new queue file and set correct permissions
echo "🆕 Creating new queue file..."
touch "$QUEUE_FILE"
chmod 600 "$QUEUE_FILE"

echo "✅ FileZilla queue reset and cleaned successfully!"
````

---

## 📄 How to Use

1. **Save** the script as `fix-filezilla-queue.sh` in your preferred scripts directory.
2. **Make it executable:**

   ```bash
   chmod +x fix-filezilla-queue.sh
   ```
3. **Run it directly:**

   ```bash
   ./fix-filezilla-queue.sh
   ```
4. **(Optional)** Install globally:

   ```bash
   sudo install -m 755 fix-filezilla-queue.sh /usr/local/bin/fix-filezilla-queue
   ```

   Then run it from anywhere:

   ```bash
   fix-filezilla-queue
   ```

---

## 🧠 Notes

* This only affects the **transfer queue** — your saved sites, settings, and credentials remain untouched.
* You can safely delete the backup (`queue.sqlite3.bak.*`) files later.
* Works on **Linux** (and macOS with minor path adjustments).
* Store this file in your Obsidian `Scripts` or `System Maintenance` folder for quick reference.

---

## ✅ Example Output

```
🔧 Checking FileZilla queue at: /home/ray/.config/filezilla/queue.sqlite3
🧹 Removing stale SQLite journal files...
📦 Backing up old queue file to: /home/ray/.config/filezilla/queue.sqlite3.bak.20251011194512
🆕 Creating new queue file...
✅ FileZilla queue reset and cleaned successfully!
```

---

*Document maintained by **rwxray** — part of the `Linux Maintenance Scripts` collection.*

