#!/bin/bash
# Install systemd service and timer for bt-battery.sh for the current user

# Directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

# Ensure user systemd directory exists
mkdir -p "$SYSTEMD_USER_DIR"

# Copy service and timer files
cp "$SCRIPT_DIR/systemd/bt-battery.service" "$SYSTEMD_USER_DIR/"
cp "$SCRIPT_DIR/systemd/bt-battery.timer" "$SYSTEMD_USER_DIR/"

# Reload systemd user daemon
systemctl --user daemon-reload

# Enable and start the timer
systemctl --user enable bt-battery.timer
systemctl --user start bt-battery.timer

echo "bt-battery systemd timer installed and started for the current user."
echo "Check status with: systemctl --user status bt-battery.timer"
