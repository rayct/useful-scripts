#!/bin/bash
# safe-suspend.sh — Graceful suspend with logging, notifications, optional reboot,
# and a pre-suspend confirmation prompt.

LOGFILE="$HOME/safe-suspend.log"
MAX_FAILS=3
FAIL_COUNT_FILE="$HOME/.safe-suspend-fails"

NOTIFY() { notify-send "Safe Suspend" "$1" -i system-suspend -t 3000; }

ASK_YES_NO() {
    zenity --question --title="Safe Suspend" --text="$1" --width=300
}

# Log start
echo "[$(date)] Initiating Safe Suspend..." | tee -a "$LOGFILE"
NOTIFY "Checking system before suspend..."

# (Optional future checks — inhibitors, battery, etc.)
echo "[$(date)] System check complete. Ready for suspend." | tee -a "$LOGFILE"

# Ask user before suspend
if ASK_YES_NO "System is ready. Do you want to suspend now?"; then
    echo "[$(date)] User confirmed suspend. Attempting normal suspend..." | tee -a "$LOGFILE"
    NOTIFY "Attempting normal suspend..."

    if ! systemctl suspend 2>>"$LOGFILE"; then
        echo "[$(date)] Normal suspend failed. Checking inhibitors..." | tee -a "$LOGFILE"
        NOTIFY "Normal suspend failed. Checking inhibitors..."

        # Log possible blockers
        ps -eo pid,comm,user,etime | grep -E 'vlc|mpv|chrome|firefox|cinnamon-session|vmware|virtualbox|steam|zoom|teams' \
            | grep -v grep >>"$LOGFILE"

        echo "[$(date)] Waiting 2 seconds, then forcing suspend..." | tee -a "$LOGFILE"
        NOTIFY "Inhibitors logged to $LOGFILE. Forcing suspend in 2 seconds..."
        sleep 2

        if ! systemctl suspend -i 2>>"$LOGFILE"; then
            echo "[$(date)] Forced suspend failed." | tee -a "$LOGFILE"
            NOTIFY "Forced suspend failed!"

            # Increment failure count
            COUNT=$(cat "$FAIL_COUNT_FILE" 2>/dev/null || echo 0)
            COUNT=$((COUNT + 1))
            echo "$COUNT" >"$FAIL_COUNT_FILE"

            if [ "$COUNT" -ge "$MAX_FAILS" ]; then
                echo "[$(date)] Reached $COUNT failed suspend attempts. Prompting for reboot." | tee -a "$LOGFILE"
                if ASK_YES_NO "Suspend failed multiple times. Reboot instead?"; then
                    echo "[$(date)] User agreed to reboot." | tee -a "$LOGFILE"
                    NOTIFY "Rebooting now..."
                    rm -f "$FAIL_COUNT_FILE"
                    systemctl reboot
                else
                    echo "[$(date)] User declined reboot." | tee -a "$LOGFILE"
                    NOTIFY "Okay, not rebooting."
                fi
            fi
        else
            echo "[$(date)] Forced suspend succeeded." | tee -a "$LOGFILE"
            echo 0 >"$FAIL_COUNT_FILE"
        fi
    else
        echo "[$(date)] Normal suspend succeeded." | tee -a "$LOGFILE"
        echo 0 >"$FAIL_COUNT_FILE"
    fi
else
    echo "[$(date)] User declined suspend." | tee -a "$LOGFILE"
    NOTIFY "Suspend canceled by user."
fi
echo "[$(date)] Safe Suspend process complete." | tee -a "$LOGFILE"
NOTIFY "Safe Suspend process complete."
exit 0
