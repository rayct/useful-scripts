#!/bin/bash

SWAP_DIR="$HOME/.local/state/nvim/swap"

echo "🔍 Checking for stale Neovim swap files in: $SWAP_DIR"
echo

find "$SWAP_DIR" -type f -name "*.swp" | while read -r swpfile; do
  echo "Found swap: $swpfile"

  # Use strings to extract PID and filename from swap file
  PID=$(strings "$swpfile" | grep -m1 '^process ID: ' | awk '{print $3}')
  FILE=$(strings "$swpfile" | grep -m1 '^file name: ' | cut -d: -f2- | xargs)

  if [[ -z "$PID" ]]; then
    echo "  ⚠️  Could not detect PID. Skipping."
    continue
  fi

  # Check if the process is still running
  if ps -p "$PID" > /dev/null 2>&1; then
    echo "  ⏳ Process $PID is still running — swap file may still be active."
  else
    echo "  🪦 Process $PID is NOT running — stale swap file."
    echo "  📄 Related file: $FILE"

    read -p "  ➤ Delete this swap file? [y/N]: " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
      rm "$swpfile"
      echo "  ✅ Deleted $swpfile"
    else
      echo "  ❌ Skipped"
    fi
  fi

  echo
done

