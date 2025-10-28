Auto Clipboard Clear Daemon (BASH) Script

It includes:

* Script overview
* Installation & usage guide
* Full Bash daemon script
* Optional `systemd` service setup for autostart

---

# 🧰 Auto Clipboard Clear Daemon (Bash)

A lightweight Bash daemon that **automatically clears your clipboard** at configurable time intervals.  
Designed for **macOS** and **Linux**, with logging in **UK/GB timezone**.

---

## 📋 Features

- Automatically clears clipboard at custom intervals  
- Works on macOS (`pbcopy`) and Linux (`xclip` / `xsel`)  
- Logs all actions to `clipboard_clear_log.txt` with UK timestamps  
- Runs quietly as a daemon (background process)  
- PID tracking for easy start/stop/status  
- Optional `systemd` service for autostart on boot  

---

## ⚙️ Installation

1. Copy the script below into a file named:
```

auto_clear_clipboard_daemon.sh

````

2. Make it executable:
```bash
chmod +x auto_clear_clipboard_daemon.sh
````

3. (Optional) Install dependencies if needed:

   ```bash
   # macOS (comes with pbcopy)
   # Linux users:
   sudo apt install xclip      # or: sudo apt install xsel
   ```

---

## 🧩 Bash Script

```bash
#!/usr/bin/env bash
# auto_clear_clipboard_daemon.sh
# Automatically clears the system clipboard at set intervals.
# Logs actions to a .txt file with UK/GB timestamps.

# --- CONFIGURATION ---
INTERVAL=${2:-300}  # Default: 300 seconds (5 minutes)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/clipboard_clear_log.txt"
PID_FILE="$SCRIPT_DIR/clipboard_clear_daemon.pid"

# Set timezone to UK (Europe/London)
export TZ="Europe/London"

# --- FUNCTIONS ---
clear_clipboard() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')

    if command -v pbcopy &>/dev/null; then
        echo -n "" | pbcopy
        echo "[$timestamp] Clipboard cleared (macOS)" >> "$LOG_FILE"
    elif command -v xclip &>/dev/null; then
        echo -n "" | xclip -selection clipboard
        echo "[$timestamp] Clipboard cleared (Linux, xclip)" >> "$LOG_FILE"
    elif command -v xsel &>/dev/null; then
        echo -n "" | xsel --clipboard --input
        echo "[$timestamp] Clipboard cleared (Linux, xsel)" >> "$LOG_FILE"
    else
        echo "[$timestamp] ERROR: No supported clipboard utility found." >> "$LOG_FILE"
        exit 1
    fi
}

start_daemon() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Daemon is already running (PID: $(cat "$PID_FILE"))"
        exit 0
    fi

    echo "Starting clipboard clear daemon... (interval: $INTERVAL seconds)"
    echo "Logs: $LOG_FILE"

    (
        echo $$ > "$PID_FILE"
        echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] Daemon started with interval $INTERVAL seconds." >> "$LOG_FILE"
        while true; do
            clear_clipboard
            sleep "$INTERVAL"
        done
    ) &
}

stop_daemon() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        kill "$(cat "$PID_FILE")"
        echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] Daemon stopped." >> "$LOG_FILE"
        rm -f "$PID_FILE"
        echo "Daemon stopped."
    else
        echo "No running daemon found."
    fi
}

status_daemon() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Daemon is running (PID: $(cat "$PID_FILE"))"
    else
        echo "Daemon is not running."
    fi
}

# --- MAIN EXECUTION ---
case "$1" in
    start|"")
        start_daemon
        ;;
    stop)
        stop_daemon
        ;;
    status)
        status_daemon
        ;;
    *)
        echo "Usage: $0 {start|stop|status} [interval_seconds]"
        ;;
esac
```

---

## ▶️ Usage

Start daemon (default 5 minutes):

```bash
./auto_clear_clipboard_daemon.sh start
```

Start with custom interval (e.g., 10 minutes):

```bash
./auto_clear_clipboard_daemon.sh start 600
```

Stop daemon:

```bash
./auto_clear_clipboard_daemon.sh stop
```

Check daemon status:

```bash
./auto_clear_clipboard_daemon.sh status
```

---

## 🧾 Logging

All actions are written to:

```
clipboard_clear_log.txt
```

Example log entry:

```
[2025-10-28 14:32:05 GMT] Clipboard cleared (Linux, xclip)
```

---

## 🔄 Optional: Systemd Service (Linux Only)

To have it start automatically on boot:

1. Create a systemd unit file:

   ```bash
   sudo nano /etc/systemd/system/auto-clear-clipboard.service
   ```

2. Paste this content (update path to your script):

   ```ini
   [Unit]
   Description=Auto Clipboard Clear Daemon
   After=network.target

   [Service]
   ExecStart=/path/to/auto_clear_clipboard_daemon.sh start 300
   ExecStop=/path/to/auto_clear_clipboard_daemon.sh stop
   Restart=always
   User=%i
   WorkingDirectory=/path/to/

   [Install]
   WantedBy=multi-user.target
   ```

3. Enable and start it:

   ```bash
   sudo systemctl enable auto-clear-clipboard.service
   sudo systemctl start auto-clear-clipboard.service
   ```

4. Check status:

   ```bash
   sudo systemctl status auto-clear-clipboard.service
   ```

---

## ✅ Notes

* Ensure the script and log file are **writable** by your user.
* If using `xclip` or `xsel`, the script must run under a **session with access to DISPLAY** (e.g., your desktop session).
* To fully daemonize without a terminal, you can also use:

  ```bash
  nohup ./auto_clear_clipboard_daemon.sh start &
  disown
  ```

---

**Author:** rwxray
**License:** MIT
**Timezone:** Europe/London 🇬🇧

_**Documentation Maintained By:** Raymond C. Turner_

_**Date:**October 28th, 2025_
