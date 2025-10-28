#!/usr/bin/env bash
# auto_clear_clipboard_daemon.sh
# Automatically clears the system clipboard at set intervals.
# Logs actions with UK/GB timestamps and supports optional notifications.

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

clear_clipboard() {
    local timestamp
    timestamp=$(date '+%d-%m-%Y %H:%M:%S %Z')

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
        echo "[$(date '+%d-%m-%Y %H:%M:%S %Z')] Daemon started (interval $INTERVALs)." >> "$LOG_FILE"
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
        echo "[$(date '+%d-%m-%Y %H:%M:%S %Z')] Daemon stopped." >> "$LOG_FILE"
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
