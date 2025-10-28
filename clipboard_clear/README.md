Perfect — this final version does **everything**:
✅ Clipboard clearing daemon (macOS + Linux)
✅ Logging with UK timestamps
✅ Pre-clear clipboard content logged to `clipboard_clear_log.txt`
✅ Optional notifications with customizable title/message
✅ `systemd` + `launchd` autostart support
✅ New **Testing & Troubleshooting** section

Here’s your full Markdown document ready for Git or Obsidian:

---

```markdown
# 🧰 Auto Clipboard Clear Daemon (Bash)

A secure, cross-platform Bash daemon that **automatically clears your clipboard** at configurable intervals.  
Includes **logging**, **optional notifications**, and **autostart** support for both Linux and macOS.  

---

## 📋 Features

- Clears clipboard automatically at user-defined intervals  
- Works on macOS (`pbcopy`) and Linux (`xclip` / `xsel`)  
- Logs **pre-clear clipboard content** (for auditing or debugging)  
- UK/GB timezone logging  
- Optional desktop notifications  
- Fully daemonized with start/stop/status commands  
- Autostart support for `systemd` (Linux) and `launchd` (macOS)  

---

## ⚙️ Installation

1. Save as:
```

auto_clear_clipboard_daemon.sh

````

2. Make it executable:
```bash
chmod +x auto_clear_clipboard_daemon.sh
````

3. (Optional) Install dependencies:

   ```bash
   # macOS: pbcopy and osascript are built-in
   # Linux:
   sudo apt install xclip libnotify-bin     # or: sudo apt install xsel libnotify-bin
   ```

---

## 🧩 Bash Script

```bash
#!/usr/bin/env bash
# auto_clear_clipboard_daemon.sh
# Automatically clears the system clipboard at set intervals.
# Logs clipboard contents pre-clearing, timestamps, and sends optional desktop notifications.

# --- CONFIGURATION ---
INTERVAL=${2:-300}                  # Default: 300 seconds (5 minutes)
NOTIFY_SEND=${NOTIFY_SEND:-1}       # 1 = show notification, 0 = silent
NOTIFY_TITLE=${NOTIFY_TITLE:-"Clipboard Cleared"}
NOTIFY_MSG=${NOTIFY_MSG:-"Your clipboard has been securely cleared."}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/clipboard_clear_log.txt"
PID_FILE="$SCRIPT_DIR/clipboard_clear_daemon.pid"

# Set timezone to UK (Europe/London)
export TZ="Europe/London"

# --- FUNCTIONS ---
send_notification() {
    local custom_message="$1"
    if [ "$NOTIFY_SEND" -eq 1 ]; then
        if command -v notify-send &>/dev/null; then
            notify-send "$NOTIFY_TITLE" "${custom_message:-$NOTIFY_MSG}"
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            osascript -e "display notification \"${custom_message:-$NOTIFY_MSG}\" with title \"$NOTIFY_TITLE\""
        fi
    fi
}

get_clipboard_content() {
    if command -v pbpaste &>/dev/null; then
        pbpaste
    elif command -v xclip &>/dev/null; then
        xclip -selection clipboard -o 2>/dev/null
    elif command -v xsel &>/dev/null; then
        xsel --clipboard --output 2>/dev/null
    else
        echo "[Clipboard read unavailable]"
    fi
}

clear_clipboard() {
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S %Z')

    # Capture pre-clear clipboard content
    local clipboard_content
    clipboard_content=$(get_clipboard_content)

    {
        echo "[$timestamp] Clipboard content before clearing:"
        echo "------------------------------------------------------------"
        echo "$clipboard_content"
        echo "------------------------------------------------------------"
    } >> "$LOG_FILE"

    # Clear clipboard
    if command -v pbcopy &>/dev/null; then
        echo -n "" | pbcopy
        echo "[$timestamp] Clipboard cleared (macOS)" >> "$LOG_FILE"
        send_notification "Clipboard cleared at $timestamp"
    elif command -v xclip &>/dev/null; then
        echo -n "" | xclip -selection clipboard
        echo "[$timestamp] Clipboard cleared (Linux, xclip)" >> "$LOG_FILE"
        send_notification "Clipboard cleared at $timestamp"
    elif command -v xsel &>/dev/null; then
        echo -n "" | xsel --clipboard --input
        echo "[$timestamp] Clipboard cleared (Linux, xsel)" >> "$LOG_FILE"
        send_notification "Clipboard cleared at $timestamp"
    else
        echo "[$timestamp] ERROR: No supported clipboard utility found." >> "$LOG_FILE"
        send_notification "Error: No supported clipboard utility found."
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
        echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] Daemon started (interval $INTERVALs)." >> "$LOG_FILE"
        send_notification "Clipboard clear daemon started (interval: $INTERVALs)"
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
        send_notification "Clipboard clear daemon stopped."
        echo "Daemon stopped."
    else
        echo "No running daemon found."
    fi
}

status_daemon() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "Daemon running (PID: $(cat "$PID_FILE"))"
    else
        echo "Daemon not running."
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

Start daemon (default 5 min):

```bash
./auto_clear_clipboard_daemon.sh start
```

Start with custom interval (e.g. 10 min):

```bash
./auto_clear_clipboard_daemon.sh start 600
```

Stop daemon:

```bash
./auto_clear_clipboard_daemon.sh stop
```

Check status:

```bash
./auto_clear_clipboard_daemon.sh status
```

Disable notifications:

```bash
NOTIFY_SEND=0 ./auto_clear_clipboard_daemon.sh start
```

Custom notification title/message:

```bash
NOTIFY_TITLE="Security Alert" NOTIFY_MSG="Clipboard was purged." ./auto_clear_clipboard_daemon.sh start
```

---

## 🧾 Logging

All actions are recorded in:

**clipboard_clear_log.txt**

Example entry:

```bash
[2025-10-28 15:01:43 GMT] Clipboard content before clearing:
------------------------------------------------------------
Sensitive text or password sample
------------------------------------------------------------
[2025-10-28 15:01:43 GMT] Clipboard cleared (Linux, xclip)
```

---

## 🔔 Notifications

* **Linux:** via `notify-send` (`libnotify-bin`)
* **macOS:** via `osascript` (native notifications)
* Customization:

  ```bash
  NOTIFY_SEND=1
  NOTIFY_TITLE="Clipboard Cleared"
  NOTIFY_MSG="Your clipboard was securely wiped."
  ```

---

## 🔄 Autostart Options

### 🐧 Linux (systemd)

1. Create:

   ```bash
   sudo nano /etc/systemd/system/auto-clear-clipboard.service
   ```

2. Paste:

   ```ini
   [Unit]
   Description=Auto Clipboard Clear Daemon
   After=network.target

   [Service]
   ExecStart=/path/to/auto_clear_clipboard_daemon.sh start 300
   ExecStop=/path/to/auto_clear_clipboard_daemon.sh stop
   Restart=always
   User=%i
   Environment=NOTIFY_SEND=0
   Environment=NOTIFY_TITLE=Clipboard Cleared
   Environment=NOTIFY_MSG=Clipboard wiped securely.
   WorkingDirectory=/path/to/

   [Install]
   WantedBy=multi-user.target
   ```

3. Enable/start:

   ```bash
   sudo systemctl enable auto-clear-clipboard.service
   sudo systemctl start auto-clear-clipboard.service
   ```

4. Check:

   ```bash
   sudo systemctl status auto-clear-clipboard.service
   ```

---

### 🍏 macOS (launchd)

1. Create:

   ```bash
   nano ~/Library/LaunchAgents/com.rwxray.clipboardclear.plist
   ```

2. Paste:

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" 
       "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>Label</key><string>com.rwxray.clipboardclear</string>
       <key>ProgramArguments</key>
       <array>
           <string>/usr/local/bin/bash</string>
           <string>/path/to/auto_clear_clipboard_daemon.sh</string>
           <string>start</string>
           <string>300</string>
       </array>
       <key>EnvironmentVariables</key>
       <dict>
           <key>NOTIFY_SEND</key><string>1</string>
           <key>NOTIFY_TITLE</key><string>Clipboard Cleared</string>
           <key>NOTIFY_MSG</key><string>Your clipboard was securely wiped.</string>
       </dict>
       <key>RunAtLoad</key><true/>
       <key>KeepAlive</key><true/>
       <key>WorkingDirectory</key><string>/path/to/</string>
       <key>StandardOutPath</key><string>/path/to/clipboard_clear_log.txt</string>
       <key>StandardErrorPath</key><string>/path/to/clipboard_clear_log.txt</string>
   </dict>
   </plist>
   ```

3. Load/start:

   ```bash
   launchctl load ~/Library/LaunchAgents/com.rwxray.clipboardclear.plist
   launchctl start com.rwxray.clipboardclear
   ```

4. Stop/unload:

   ```bash
   launchctl stop com.rwxray.clipboardclear
   launchctl unload ~/Library/LaunchAgents/com.rwxray.clipboardclear.plist
   ```

---

## 🧪 Testing & Troubleshooting

### ✅ Verify Clipboard Operations

```bash
echo "test123" | xclip -selection clipboard
xclip -selection clipboard -o
```

Expected output: `test123`

### ✅ Test Notifications

```bash
notify-send "Clipboard Cleared" "Test notification works"
```

(macOS)

```bash
osascript -e 'display notification "Test notification works" with title "Clipboard Cleared"'
```

### ✅ Check Logs

```bash
tail -n 10 clipboard_clear_log.txt
```

### ✅ Debugging Daemon

Check PID and running status:

```bash
ps aux | grep auto_clear_clipboard_daemon
```

Stop all instances if necessary:

```bash
pkill -f auto_clear_clipboard_daemon.sh
```

---

## 🔐 Security Notes

* Logs include **clipboard contents before clearing** — use responsibly.
* Recommended interval for sensitive data: **30–120 seconds**.
* The script clears the **system clipboard only**, not application-specific buffers.
* On Linux, the daemon must run in a graphical session with `DISPLAY` access.

---

Would you like me to add an **optional encryption layer** for the logged clipboard contents (e.g., encrypt logs with GPG or OpenSSL)?

---

---

**Author:** rwxray
**License:** MIT
**Timezone:** Europe/London 🇬🇧
**Version:** 1.0.0

_**Documentation Maintained By:** Raymond C. Turner_

_**Date:**October 28th, 2025_
