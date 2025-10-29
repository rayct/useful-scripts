#!/usr/bin/env bash
# clipboard_clear.sh
# Clears the clipboard only if its contents are older than a set threshold.
# Logs activity and sends desktop notifications.
# Designed for systemd timer or manual use. Compatible with Linux/macOS.

# --- CONFIGURATION ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$SCRIPT_DIR/clipboard_clear_log.txt"
STATE_FILE="$SCRIPT_DIR/clipboard_last_content.txt"
THRESHOLD_MINUTES=5      # Minimum age before clearing (in minutes)
export TZ="Europe/London"

# --- FUNCTIONS ---
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S %Z')] $1"
    echo "$msg" | tee -a "$LOG_FILE"
}

notify_user() {
    local message="$1"
    if command -v notify-send &>/dev/null; then
        notify-send "Clipboard Auto Clear" "$message"
    elif command -v osascript &>/dev/null; then
        osascript -e "display notification \"$message\" with title \"Clipboard Auto Clear\""
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

set_clipboard_content() {
    if command -v pbcopy &>/dev/null; then
        echo -n "$1" | pbcopy
    elif command -v xclip &>/dev/null; then
        echo -n "$1" | xclip -selection clipboard
    elif command -v xsel &>/dev/null; then
        echo -n "$1" | xsel --clipboard --input
    fi
}

clipboard_needs_clearing() {
    # If state file doesn’t exist, create it and skip clearing
    if [ ! -f "$STATE_FILE" ]; then
        get_clipboard_content > "$STATE_FILE"
        date +%s > "${STATE_FILE}.time"
        log "State initialized; clipboard clear skipped this cycle."
        return 1
    fi

    local current_content saved_content
    current_content="$(get_clipboard_content)"
    saved_content="$(cat "$STATE_FILE")"

    # If clipboard changed, update and skip clearing
    if [[ "$current_content" != "$saved_content" ]]; then
        log "Clipboard changed since last check; skipping clear."
        echo "$current_content" > "$STATE_FILE"
        date +%s > "${STATE_FILE}.time"
        return 1
    fi

    # Compare elapsed time since last change
    local last_time current_time elapsed threshold_seconds
    last_time=$(cat "${STATE_FILE}.time" 2>/dev/null || echo 0)
    current_time=$(date +%s)
    elapsed=$((current_time - last_time))
    threshold_seconds=$((THRESHOLD_MINUTES * 60))

    if (( elapsed >= threshold_seconds )); then
        return 0  # true: needs clearing
    else
        log "Clipboard unchanged but below age threshold (${elapsed}s < ${threshold_seconds}s)."
        return 1
    fi
}

clear_clipboard_if_old() {
    if clipboard_needs_clearing; then
        local before_clear
        before_clear="$(get_clipboard_content)"
        log "Clearing clipboard. Previous contents: ${before_clear:-<empty>}"
        set_clipboard_content ""
        log "Clipboard cleared (unchanged for ${THRESHOLD_MINUTES} minutes)."
        notify_user "Clipboard cleared after ${THRESHOLD_MINUTES} minutes of inactivity."
    fi
}

# --- MAIN EXECUTION ---
clear_clipboard_if_old
exit 0