# Stop and disable the systemd timer and service
systemctl --user disable --now update-flatpaks-clean.timer 2>/dev/null
systemctl --user disable --now update-flatpaks-clean.service 2>/dev/null

# Remove the unit files
rm -f ~/.config/systemd/user/update-flatpaks-clean.timer
rm -f ~/.config/systemd/user/update-flatpaks-clean.service

# Reload systemd to clear cached units
systemctl --user daemon-reload
systemctl --user reset-failed

# Remove the Flatpak cleaner script and logs
rm -f ~/.local/bin/update-flatpaks-clean.sh
rm -f ~/.local/share/flatpak-clean-updates.log

# Confirmation message
echo "✅ Clean Flatpak updater completely removed."
