#!/bin/bash
# Auto sync Obsidian notes with GitHub (SSH)
# Logs to notes/git-sync.log, keeps last 100 entries, sends desktop notifications

VAULT_DIR=~/notes
LOGFILE="$VAULT_DIR/git-sync.log"

# Ensure the vault directory exists
if [ ! -d "$VAULT_DIR" ]; then
  notify-send "❌ Git Sync Failed" "Vault directory not found: $VAULT_DIR"
  exit 1
fi

# Rotate logs — keep only last 100 entries
if [ -f "$LOGFILE" ]; then
  tail -n 100 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
fi

{
  echo "--------------------------------------------"
  echo "🕒 Sync started: $(date '+%d-%m-%Y %H:%M:%S')"
  cd "$VAULT_DIR" || { echo "❌ Vault directory not found: $VAULT_DIR"; exit 1; }

  echo "🔄 Pulling latest changes..."
  git pull --rebase

  echo "📦 Adding and committing changes..."
  git add .
  git commit -m "Auto update: $(date '+%d-%m-%Y %H:%M:%S')" || echo "No changes to commit."

  echo "🚀 Pushing to GitHub..."
  git push

  echo "✅ Sync complete."
  echo
} >> "$LOGFILE" 2>&1

# Desktop notification
if grep -qi "error" "$LOGFILE"; then
  notify-send "⚠️ Git Sync Error" "Check git-sync.log in your notes folder for details."
else
  notify-send "✅ Git Sync Complete" "Notes synced at $(date '+%H:%M')"
fi

