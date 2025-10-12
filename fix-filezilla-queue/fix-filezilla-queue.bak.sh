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
