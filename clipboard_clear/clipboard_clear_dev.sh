#!/usr/bin/env bash
# auto_clear_clipboard_daemon.sh
# Automatically clears clipboard at custom intervals, logs events, and self-manages duplicate daemons.
# Compatible with Linux/macOS. Uses notify-send and logs clipboard contents before clearing.

# --- CONFIGURATION ---
INTERVAL=${1:-300}  # Default: 300 seconds (5 minutes)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/clipboard_clear_log.txt"
PID_FILE="$SCRIPT_DIR/clipboard_clear_daemon.pid"
export TZ="Europe/London"

# --- FUNCTIONS ---
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S %Z')] $1"
    echo "$msg" | tee -a "$LOG_FILE"
}

notify_user() {
    local message="$1"
    if command -v notify-send &>/dev/null; then
        notify-send "Clipboard Daemon" "$message"
    elif command -v osascript &>/dev/null; then
        osascript -e "display notification \"$message\" with title \"Clipboard Daemon\""
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
        echo ""
    fi
}

clear_clipboard() {
    local before_clear
    before_clear="$(get_clipboard_content)"
    log "Clipboard contents before clearing: ${before_clear:-<empty>}"

    if command -v pbcopy &>/dev/null; then
        echo -n "" | pbcopy
    elif command -v xclip &>/dev/null; then
        echo -n "" | xclip -selection clipboard
    elif command -v xsel &>/dev/null; then
        echo -n "" | xsel --clipboard --input
    fi

    log "Clipboard cleared."
    notify_user "Clipboard cleared and logged."
}

stop_existing_daemons() {
    # Stop previous daemon via PID file if valid
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if kill -0 "$OLD_PID" 2>/dev/null; then
            log "Stopping existing daemon (PID $OLD_PID)..."
            kill "$OLD_PID"
            sleep 1
        fi
        rm -f "$PID_FILE"
    fi

    # Stop any stray background processes matching the script
    local PIDS
    PIDS=$(pgrep -f "auto_clear_clipboard_daemon.sh start" || true)
    if [ -n "$PIDS" ]; then
        log "Killing old daemon processes: $PIDS"
        kill $PIDS 2>/dev/null || true
    fi
}

start_daemon() {
    stop_existing_daemons
    log "Starting new clipboard daemon (interval: ${INTERVAL}s)..."

    (
        echo $$ > "$PID_FILE"
        while true; do
            clear_clipboard
            sleep "$INTERVAL"
        done
    ) &
    log "Daemon started (PID $!). Logs written to $LOG_FILE"
}

stop_daemon() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID"
            log "Daemon stopped (PID $PID)."
        else
            log "PID file found but process not running."
        fi
        rm -f "$PID_FILE"
    else
        local PIDS
        PIDS=$(pgrep -f "auto_clear_clipboard_daemon.sh start" || true)
        if [ -n "$PIDS" ]; then
            kill $PIDS 2>/dev/null
            log "Stopped daemon(s): $PIDS"
        else
            log "No running daemon found."
        fi
    fi
}

status_daemon() {
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        log "Daemon running (PID $(cat "$PID_FILE"))"
    else
        log "Daemon not running."
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
