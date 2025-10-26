#!/bin/bash
# Auto sync Obsidian notes with GitHub (SSH)
# Logs to git-sync.log inside the vault, keeps last 100 entries, desktop notifications

# --- Configuration ---
VAULT_DIR=~/Repos/github.com/rayct/notes
LOGFILE="$VAULT_DIR/git-sync.log"
MAX_LOG_LINES=100

# --- Ensure the vault directory exists ---
if [ ! -d "$VAULT_DIR" ]; then
  notify-send "❌ Git Sync Failed" "Vault directory not found: $VAULT_DIR"
  exit 1
fi

# --- Ensure log file exists ---
touch "$LOGFILE" || { echo "❌ Cannot write to log file: $LOGFILE"; exit 1; }

# --- Rotate logs — keep only last MAX_LOG_LINES lines ---
tail -n "$MAX_LOG_LINES" "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"

# --- Perform Git operations and log output ---
{
  echo "--------------------------------------------"
  echo "🕒 Sync started: $(date '+%d-%m-%Y %H:%M:%S')"

  cd "$VAULT_DIR" || { echo "❌ Failed to change directory to vault"; exit 1; }

  echo "🔄 Pulling latest changes..."
  if ! git pull --rebase; then
    echo "❌ Git pull failed"
  fi

  echo "📦 Adding and committing changes..."
  git add .
  if ! git commit -m "Auto update: $(date '+%d-%m-%Y %H:%M:%S')" 2>/dev/null; then
    echo "No changes to commit."
  fi

  echo "🚀 Pushing to GitHub..."
  if ! git push; then
    echo "❌ Git push failed"
  fi

  echo "✅ Sync complete."
  echo
} >> "$LOGFILE" 2>&1

# --- Desktop notification based on log content ---
if grep -qi "error\|failed" "$LOGFILE"; then
  notify-send "⚠️ Git Sync Error" "Check git-sync.log in your notes folder for details."
else
  notify-send "✅ Git Sync Complete" "Notes synced at $(date '+%H:%M')"
fi
exit 0
# --- End of script ---
# --- Instructions to set up keyboard shortcut on Linux (GNOME) ---
# 1. Open "Settings" > "Keyboard" > "Keyboard Shortcuts"
# 2. Add:
#    * **Name:** Git Sync Notes
#    * **Command:** `/home/user/git-sync-notes.sh`
#    * **Shortcut:** `Ctrl + Alt + S`
# Now press `Ctrl + Alt + S` anytime to instantly sync your notes.
# --- End of instructions ---
