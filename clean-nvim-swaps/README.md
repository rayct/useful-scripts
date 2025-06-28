Here’s a **safe Bash script** that:

1. Scans for `.swp` files in Neovim's swap directory
2. Extracts the PID stored in each swap file name
3. Checks if the PID is still running
4. If not, offers to delete the stale swap file

---

### 🧼 **Script: `clean-nvim-swaps.sh`**

```bash
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
```

---

### 💾 To Use:

1. Save it:

   ```bash
   nano ~/clean-nvim-swaps.sh
   ```

   Paste the script, save with `Ctrl+O`, then `Enter`, and exit with `Ctrl+X`.

2. Make it executable:

   ```bash
   chmod +x ~/clean-nvim-swaps.sh
   ```

3. Run it:

   ```bash
   ~/clean-nvim-swaps.sh
   ```

---

### 🧠 Pro Tip: Auto-clean on boot or weekly
