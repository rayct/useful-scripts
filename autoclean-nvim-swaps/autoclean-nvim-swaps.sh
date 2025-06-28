#!/bin/bash

SWAP_DIR="$HOME/.local/state/nvim/swap"

echo "🔁 Auto-cleaning stale Neovim swap files in: $SWAP_DIR"
echo

find "$SWAP_DIR" -type f -name "*.swp" | while read -r swpfile; do
  echo "Checking: $swpfile"

  PID=$(strings "$swpfile" | grep -m1 '^process ID: ' | awk '{print $3}')
  FILE=$(strings "$swpfile" | grep -m1 '^file name: ' | cut -d: -f2- | xargs)

  if [[ -z "$PID" ]]; then
    echo "  ⚠️  No PID found. Skipping."
    continue
  fi

  if ps -p "$PID" > /dev/null 2>&1; then
    echo "  🔒 Process $PID is active — keeping swap."
  else
    echo "  🧹 Deleting stale swap for $FILE"
    rm -f "$swpfile"
  fi

  echo
done

