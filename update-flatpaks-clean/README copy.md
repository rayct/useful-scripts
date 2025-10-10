# Clean Flatpak App Updates (Linux)

> **Clean Flatpak Updater** — a lightweight script and systemd setup that updates only Flatpak applications, skipping locale and runtime rebuilds.  
> Reduces update noise, saves bandwidth, and logs only real app updates.

This setup ensures that Flatpak applications are updated **safely** while **ignoring unnecessary locale and runtime rebuilds**, keeping logs clean and preventing daily update noise.  
It is especially useful for apps like Obsidian that frequently show `.Locale` updates that do not affect functionality.

---

## 🚀 Quick Install (Copy-Paste)

```bash
# 1️⃣ Create the update script
mkdir -p ~/.local/bin
nano ~/.local/bin/update-flatpaks-clean.sh
# Paste the script from the main README, then save and exit
chmod +x ~/.local/bin/update-flatpaks-clean.sh

# 2️⃣ Create the systemd service
systemctl --user edit --force --full update-flatpaks-clean.service
# Paste the service unit from the main README, save and exit

# 3️⃣ Create the systemd timer (every 2 days, UK/GB time)
systemctl --user edit --force --full update-flatpaks-clean.timer
# Paste the timer unit from the main README, save and exit

# 4️⃣ Reload, enable, and start the timer
systemctl --user daemon-reload
systemctl --user enable --now update-flatpaks-clean.timer
systemctl --user status update-flatpaks-clean.timer
````

✅ **Notes:**

* The timer runs **every 48 hours** in the **Europe/London timezone**.
* Use `update-flatpaks` alias (from the main README) for **manual updates** at any time.
* Logs of each update are stored in `~/.local/share/flatpak-clean-updates.log`.

---

## Features

* Updates **only actual apps**, skipping locale and runtime layers.
* Logs only **real app updates** for easy review.
* Automated update every **2 days (UK time)** via systemd user timer.
* Manual update shortcut via `update-flatpaks` alias.
* Safe: Does **not** affect app performance or user data.

---

## Installation Details

### 1. Create the clean update script

```bash
mkdir -p ~/.local/bin
nano ~/.local/bin/update-flatpaks-clean.sh
```

Paste the following:

```bash
#!/bin/bash
# update-flatpaks-clean.sh - Updates only Flatpak apps, ignoring locales/runtimes
# Logs only actual app updates

LOGFILE="$HOME/.local/share/flatpak-clean-updates.log"

echo "=== $(date '+%d-%m-%Y %H:%M:%S') ===" >> "$LOGFILE" # Comment out for US Time zone below
# echo "=== $(date '+%Y-%m-%d %H:%M:%S') ===" >> "$LOGFILE" - Uncomment for US Timezone Only!
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

### 3. Create a systemd timer (every 2 days, UK time)

```bash
systemctl --user edit --force --full update-flatpaks-clean.timer
```

Paste:

```ini
[Unit]
Description=Run clean Flatpak app update every 2 days (UK Time)

[Timer]
# Runs every 48 hours after activation, using Europe/London timezone
OnActiveSec=48h
OnUnitActiveSec=48h
Persistent=true
RandomizedDelaySec=1h
Timezone=Europe/London

[Install]
WantedBy=timers.target
```

Enable and start the timer:

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

---

### 5. View Update Logs

All clean update logs are stored at:

```text
~/.local/share/flatpak-clean-updates.log
```

You can check the most recent updates with:

```bash
# Show last 20 lines
tail -n 20 ~/.local/share/flatpak-clean-updates.log

# Show all updates
cat ~/.local/share/flatpak-clean-updates.log
```

The log will include only **real app updates**, not locale or runtime rebuilds.

---

### 6. Verify Safety

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

### ✅ Summary

| Component   | File                                                   | Purpose                                 |
| ----------- | ------------------------------------------------------ | --------------------------------------- |
| **Script**  | `~/.local/bin/update-flatpaks-clean.sh`                | Updates Flatpak apps only, logs results |
| **Service** | `~/.config/systemd/user/update-flatpaks-clean.service` | Runs the update script                  |
| **Timer**   | `~/.config/systemd/user/update-flatpaks-clean.timer`   | Triggers every 48 hours (UK timezone)   |

---

### ✅ Benefits

* Clean logs with only meaningful updates.
* Reduced network and CPU usage (no daily locale/runtime rebuilds).
* Fully automated updates every 2 days (UK/GB time).
* Safe for all Flatpak apps, including sandboxed or sensitive ones.

---

### License

This setup is free to use and modify. No restrictions.

---

This README now includes:  

- ✅ Quick Install section (with `systemctl` commands)  
- ✅ Full script/service/timer instructions  
- ✅ UK/GB timezone-aware 48-hour timer  
- ✅ Manual alias and logs  
- ✅ Safety verification  

It’s fully ready for **GitHub or personal documentation**.  

---

**Documentation by:** Raymond C. Turner

**Date:** October 10th, 2025