#!/bin/bash
# Auto sync Obsidian notes with GitHub (SSH)
# Logs all actions to ~/git-sync.log and sends desktop notifications

LOGFILE=~/git-sync.log
VAULT_DIR=~/notes

{
  echo "--------------------------------------------"
  echo "🕒 Sync started: $(date '+%Y-%m-%d %H:%M:%S')"
  cd "$VAULT_DIR" || { echo "❌ Vault directory not found: $VAULT_DIR"; notify-send "Git Sync Failed" "Vault directory not found."; exit 1; }

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
if grep -q "error" "$LOGFILE"; then
  notify-send "⚠️ Git Sync Error" "Check ~/git-sync.log for details."
else
  notify-send "✅ Git Sync Complete" "Notes synced at $(date '+%H:%M')"
fi


