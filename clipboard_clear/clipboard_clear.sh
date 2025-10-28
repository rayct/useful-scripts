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
        echo "[$(date '+%d-%m-%Y %H:%M:%S %Z')] Daemon started with interval $INTERVAL seconds." >> "$LOG_FILE"
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

