#!/bin/bash
# update-flatpaks-clean.sh - Updates only Flatpak apps, ignoring locales/runtimes
# Logs only actual app updates

LOGFILE="$HOME/.local/share/flatpak-clean-updates.log"

echo "=== $(date '+%d-%m-%Y %H:%M:%S') ===" >> "$LOGFILE"
UPDATES=$(flatpak update --app --assumeyes --noninteractive 2>/dev/null)

if [ -z "$UPDATES" ]; then
    echo "No app updates found." >> "$LOGFILE"
else
    echo "Apps updated:" >> "$LOGFILE"
    echo "$UPDATES" >> "$LOGFILE"
fi

echo "-----------------------------------" >> "$LOGFILE"

