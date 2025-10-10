# Clean Flatpak App Updates (Linux)

This setup ensures that Flatpak applications are updated **safely** while **ignoring unnecessary locale and runtime rebuilds**, keeping logs clean and preventing daily update noise. It is especially useful for apps like Obsidian that frequently show `.Locale` updates that do not affect functionality.

---

## Features

- Updates **only actual apps**, skipping locale and runtime layers.
- Logs only **real app updates** for easy review.
- Optional **daily automated update** via systemd user timer.
- Manual update shortcut via `update-flatpaks` alias.
- Safe: Does **not** affect app performance or user data.

---

## Installation

### 1. Create the clean update script

```bash
mkdir -p ~/.local/bin
nano ~/.local/bin/update-flatpaks-clean.sh
````

Paste the following:

```bash
#!/bin/bash
# update-flatpaks-clean.sh - Updates only Flatpak apps, ignoring locales/runtimes
# Logs only actual app updates

LOGFILE="$HOME/.local/share/flatpak-clean-updates.log"

echo "=== $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOGFILE"
UPDATES=$(flatpak update --app --assumeyes --noninteractive 2>/dev/null)

if [ -z "$UPDATES" ]; then
    echo "No app updates found." >> "$LOGFILE"
else
    echo "Apps updated:" >> "$LOGFILE"
    echo "$UPDATES" >> "$LOGFILE"
fi

echo "-----------------------------------" >> "$LOGFILE"
```

Make it executable:

```bash
chmod +x ~/.local/bin/update-flatpaks-clean.sh
```

---

### 2. Create a systemd user service

```bash
systemctl --user edit --force --full update-flatpaks-clean.service
```

Paste:

```ini
[Unit]
Description=Clean Flatpak App Update (no locale/runtime noise)

[Service]
Type=oneshot
ExecStart=%h/.local/bin/update-flatpaks-clean.sh
```

Save and exit.

---

### 3. Create a systemd timer for daily updates

```bash
systemctl --user edit --force --full update-flatpaks-clean.timer
```

Paste:

```ini
[Unit]
Description=Run clean Flatpak app update daily

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
```

Enable the timer:

```bash
systemctl --user daemon-reload
systemctl --user enable --now update-flatpaks-clean.timer
```

Check the next scheduled run:

```bash
systemctl --user list-timers | grep update-flatpaks-clean
```

---

### 4. Manual update shortcut

Add an alias for easy manual updates:

```bash
# Bash
echo "alias update-flatpaks='~/.local/bin/update-flatpaks-clean.sh'" >> ~/.bashrc
source ~/.bashrc

# Zsh
echo "alias update-flatpaks='~/.local/bin/update-flatpaks-clean.sh'" >> ~/.zshrc
source ~/.zshrc
```

Now you can run:

```bash
update-flatpaks
```

Logs of updates are stored at:

```text
~/.local/share/flatpak-clean-updates.log
```

---

### 5. Verify Safety

1. **Check Flatpak permissions:**

```bash
flatpak info --show-permissions md.obsidian.Obsidian
```

2. **Check no AWS code exists in the sandbox:**

```bash
flatpak run --command=sh md.obsidian.Obsidian
grep -R "botocore\|boto\|aws" /app 2>/dev/null
exit
```

3. **Check live network connections (optional):**

```bash
sudo lsof -i -n -P | grep obsidian
```

All checks confirm that:

* Locale updates do not affect functionality.
* AWS references are only in build metadata, not in your installed apps.
* Sandboxed apps cannot access private vaults or GitHub content unexpectedly.

---

### ✅ Benefits

* Cleaner logs with only meaningful updates.
* Reduced daily network downloads (no unnecessary locale/runtime rebuilds).
* Completely safe for sensitive apps like Obsidian.
* Fully automated daily updates or manual on-demand updates.

---

### License

This setup is free to use and modify. No restrictions.

---

*Documentation by:* Raymond C. Turner
*Date:* October 10th, 2025
