Perfect ✅ — here’s your **final, polished `README.md`**, fully updated and ready for GitHub.
It includes:

* The clean header and project description
* Setup steps
* Verification & Troubleshooting section
* And the new **Uninstall / Remove Timer** section

---

````markdown
# 🧼 Clean Flatpak App Updates (Linux)

> **Clean Flatpak Updater** — a lightweight script and systemd setup that updates only Flatpak applications, skipping locale and runtime rebuilds.  
> Reduces update noise, saves bandwidth, and logs only real app updates.

This setup ensures that Flatpak applications are updated **safely** while **ignoring unnecessary locale and runtime rebuilds**, keeping logs clean and preventing daily update noise.  
It’s especially useful for applications like **Obsidian**, which often trigger `.Locale` updates that don’t affect functionality.

---

## ⚙️ Setup Instructions

### 1️⃣ Create the script

Create the update script at `~/.local/bin/update-flatpaks-clean.sh`:

```bash
mkdir -p ~/.local/bin
nano ~/.local/bin/update-flatpaks-clean.sh
````

Paste the following:

```bash
#!/usr/bin/env bash
LOG_FILE="$HOME/.local/share/flatpak-clean-updates.log"
mkdir -p "$(dirname "$LOG_FILE")"

{
  echo "=== $(date '+%Y-%m-%d %H:%M:%S') ==="
  flatpak update --app --noninteractive --assumeyes
  echo "-----------------------------------"
} >> "$LOG_FILE" 2>&1
```

Make it executable:

```bash
chmod +x ~/.local/bin/update-flatpaks-clean.sh
```

---

### 2️⃣ Create the systemd service

Create the file `~/.config/systemd/user/update-flatpaks-clean.service`:

```bash
mkdir -p ~/.config/systemd/user
nano ~/.config/systemd/user/update-flatpaks-clean.service
```

Paste this:

```ini
[Unit]
Description=Clean Flatpak App Update (no locale/runtime noise)

[Service]
Type=oneshot
ExecStart=%h/.local/bin/update-flatpaks-clean.sh
```

---

### 3️⃣ Create the systemd timer (UK timezone, every 2 days)

Create `~/.config/systemd/user/update-flatpaks-clean.timer`:

```bash
nano ~/.config/systemd/user/update-flatpaks-clean.timer
```

Paste this content:

```ini
[Unit]
Description=Run clean Flatpak app update every 2 days (UK Time)

[Timer]
OnActiveSec=48h
OnUnitActiveSec=48h
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
```

---

### 4️⃣ Enable and start the timer

```bash
systemctl --user daemon-reload
systemctl --user enable --now update-flatpaks-clean.timer
systemctl --user status update-flatpaks-clean.timer
```

You should see something like:

```
Active: active (waiting)
Trigger: Mon 2025-10-13 11:04:03 BST; 2 days left
```

---

## 🧩 Verification & Troubleshooting

Use these commands to manually verify that your setup is running correctly.

### ▶️ Manually run the service

```bash
systemctl --user start update-flatpaks-clean.service
```

This immediately runs your script to check for updates.

---

### 🧾 View the latest service logs

```bash
journalctl --user -u update-flatpaks-clean.service -n 20 --no-pager
```

Example:

```
Oct 11 10:25:17 ella systemd[2141]: Starting Clean Flatpak App Update (no locale/runtime noise)...
Oct 11 10:25:19 ella update-flatpaks-clean.sh[5432]: === 2025-10-11 10:25:19 ===
Oct 11 10:25:19 ella update-flatpaks-clean.sh[5432]: Apps updated:
Oct 11 10:25:19 ella systemd[2141]: update-flatpaks-clean.service: Succeeded.
Oct 11 10:25:19 ella systemd[2141]: Finished Clean Flatpak App Update (no locale/runtime noise).
```

---

### 📜 Check the update log file

```bash
cat ~/.local/share/flatpak-clean-updates.log
```

Example entry:

```
=== 2025-10-11 10:25:19 ===
Apps updated:
No app updates found.
-----------------------------------
```

---

### 🕒 Verify the timer

```bash
systemctl --user list-timers | grep update-flatpaks-clean
```

Expected output:

```
Sat 2025-10-11 10:12:33 BST; 48h left; Wed 2025-10-09 10:12:33 BST; 2 days ago
update-flatpaks-clean.timer update-flatpaks-clean.service ray ...
```

You should see:

* **Active (waiting)** in `systemctl --user status update-flatpaks-clean.timer`
* **BST (UK timezone)** for the next trigger

---

### 🔍 Full health check

Quick commands to confirm the setup at a glance:

```bash
systemctl --user list-timers | grep update-flatpaks-clean
journalctl --user -u update-flatpaks-clean.service -n 10
tail -n 10 ~/.local/share/flatpak-clean-updates.log
```

If all show normal results (no errors, “waiting” timer, log updates), your setup is working perfectly.

---

## 🧹 Uninstall / Remove the Timer Permanently

If you no longer want automatic Flatpak updates, you can permanently remove the timer, service, and script with this one-shot cleanup command:

```bash
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
```

To confirm everything is gone:

```bash
systemctl --user list-timers | grep update-flatpaks-clean
systemctl --user list-units | grep update-flatpaks-clean
```

If no output appears, the cleanup was successful.

---

## 📘 Project Summary

**Clean Flatpak Updater** is a simple, efficient Linux automation setup that:

* Updates only Flatpak **applications**
* Skips **locale** and **runtime** rebuilds
* Runs automatically every 48 hours (UK timezone)
* Logs updates cleanly for review
* Can be easily uninstalled at any time

Ideal for users who want quiet, controlled Flatpak maintenance without unnecessary daily updates.

---

```

---

Would you like me to add a **short tagline** for the GitHub repo header (under 100 characters, e.g. “Flatpak app updater with clean logs, no locale/runtime noise”)?
```
