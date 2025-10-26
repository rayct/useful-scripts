**Updated and complete `README.md`**, now reflecting the changes to the sync script:

* Logs are saved **inside the vault directory (`notes/git-sync.log`)**
* Automatically keeps only the **last 100 entries**
* All other setup details remain consistent

---

### 📄 `README.md`

# 🗒️ Obsidian Notes – Secure GitHub Sync via SSH

This repository contains my Obsidian vault (`~/notes`) synchronized securely with GitHub using SSH and a simple automated shell script.  
The setup ensures my notes are **backed up, versioned, and synced** across devices with minimal manual work.

---

## ⚙️ Overview

This workflow uses:
- **Obsidian** (note-taking app)
- **Git** (for version control)
- **GitHub** (remote backup)
- **SSH authentication** (secure, no tokens or passwords)
- **Auto-sync Bash script** with desktop notifications and rotating logs

---

## 🧩 Repository Structure

```bash
notes/
├── .git/                 # Git repo metadata
├── .obsidian/            # Obsidian settings
├── git-sync-notes.sh     # Auto-sync script
├── git-sync.log          # Sync log (rotating, last 100 entries)
└── <your-notes>.md       # Your markdown notes
````

---

## 🔒 SSH Configuration

Ensure your SSH setup is correct before using GitHub Sync:

```bash
# Directory permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub

# ~/.ssh/config example
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa
```

Test the connection:

```bash
ssh -T git@github.com
```

Expected output:

```
Hi <username>! You've successfully authenticated, but GitHub does not provide shell access.
```

---

## 🚀 Auto Sync Script

File: `~/git-sync-notes.sh`

```bash
#!/bin/bash
# Auto sync Obsidian notes with GitHub (SSH)
# Logs to notes/git-sync.log, keeps last 100 entries, sends desktop notifications

VAULT_DIR=~/notes
LOGFILE="$VAULT_DIR/git-sync.log"

# Ensure the vault directory exists
if [ ! -d "$VAULT_DIR" ]; then
  notify-send "❌ Git Sync Failed" "Vault directory not found: $VAULT_DIR"
  exit 1
fi

# Rotate logs — keep only last 100 entries
if [ -f "$LOGFILE" ]; then
  tail -n 100 "$LOGFILE" > "$LOGFILE.tmp" && mv "$LOGFILE.tmp" "$LOGFILE"
fi

{
  echo "--------------------------------------------"
  echo "🕒 Sync started: $(date '+%Y-%m-%d %H:%M:%S')"
  cd "$VAULT_DIR" || { echo "❌ Vault directory not found: $VAULT_DIR"; exit 1; }

  echo "🔄 Pulling latest changes..."
  git pull --rebase

  echo "📦 Adding and committing changes..."
  git add .
  git commit -m "Auto update: $(date '+%Y-%m-%d %H:%M:%S')" || echo "No changes to commit."

  echo "🚀 Pushing to GitHub..."
  git push

  echo "✅ Sync complete."
  echo
} >> "$LOGFILE" 2>&1

# Desktop notification
if grep -qi "error" "$LOGFILE"; then
  notify-send "⚠️ Git Sync Error" "Check git-sync.log in your notes folder for details."
else
  notify-send "✅ Git Sync Complete" "Notes synced at $(date '+%H:%M')"
fi
```

---

### 🧰 Setup

```bash
chmod +x ~/git-sync-notes.sh
```

### ▶️ Run manually

```bash
~/git-sync-notes.sh
```

### 📜 Check logs

```bash
cat ~/notes/git-sync.log
```

The log file automatically keeps only the **last 100 entries** to prevent it from growing too large.

---

## 💡 Optional Automation

### 🖥️ Desktop Launcher

Create `~/.local/share/applications/git-sync-notes.desktop`:

```ini
[Desktop Entry]
Name=Git Sync Notes
Comment=Sync Obsidian vault with GitHub
Exec=/home/ray/git-sync-notes.sh
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=Utility;
```

Make it executable:

```bash
chmod +x ~/.local/share/applications/git-sync-notes.desktop
```

### ⌨️ Keyboard Shortcut (GNOME)

1. Open **Settings → Keyboard → Shortcuts → Custom Shortcuts**
2. Add:

   * **Name:** Git Sync Notes
   * **Command:** `/home/ray/git-sync-notes.sh`
   * **Shortcut:** `Ctrl + Alt + S`

Now press `Ctrl + Alt + S` anytime to instantly sync your notes.

---

## 🧠 Recommended Daily Workflow

1. **Pull before editing:**

   ```bash
   git pull
   ```
2. **Edit in Obsidian.**
3. **Commit & push after editing:**

   ```bash
   ~/git-sync-notes.sh
   ```

This ensures you always have the latest notes and avoid merge conflicts.

---

## 🧩 Troubleshooting

**Error:** `Bad owner or permissions on ~/.ssh/config`
➡ Fix permissions:

```bash
sudo chown -R $USER:$USER ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
```

**Error:** `fatal: The current branch main has no upstream branch`
➡ Set it once:

```bash
git push --set-upstream origin main
```

---

## 🛡️ Security Notes

* SSH keys are private to your machine and far more secure than HTTPS tokens.
* Your `.ssh` directory should only be readable by you.
* Never commit or share private keys inside your repo.

---

## 🧳 Clone & Restore on a New Device

If you get a new machine and want to restore your entire Obsidian vault and sync setup:

### 1. **Install prerequisites**

```bash
sudo apt install git obsidian
```

### 2. **Set up SSH**

Copy your SSH private key to the new device (securely):

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

Then add your private key (e.g. `id_rsa` or `id_ed25519`) and fix permissions:

```bash
chmod 600 ~/.ssh/id_rsa
```

Create `~/.ssh/config` if it doesn’t exist:

```bash
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_rsa
```

Test:

```bash
ssh -T git@github.com
```

---

### 3. **Clone your notes repo**

```bash
git clone git@github.com:<username>/notes.git ~/notes
```

---

### 4. **Recreate sync script**

```bash
nano ~/git-sync-notes.sh
```

Paste in the script from above, then:

```bash
chmod +x ~/git-sync-notes.sh
```

---

### 5. **(Optional)** Add the launcher or shortcut again

* Desktop launcher: copy `.desktop` file back to
  `~/.local/share/applications/`
* Keyboard shortcut: re-add under **Settings → Keyboard → Shortcuts**

---

### 6. **Open vault in Obsidian**

1. Launch Obsidian.
2. Click **“Open folder as vault”** → choose `~/notes`.
3. Done — your synced vault is ready!

---

## 🏁 Summary

✅ **Secure:** SSH authentication
✅ **Automated:** One-click or shortcut sync
✅ **Logged:** Activity logged to `notes/git-sync.log` (rotating)
✅ **Restorable:** Clone + restore anywhere securely
✅ **Notified:** Desktop popup on success/failure

---

> *“A note not backed up is a note already lost.”* — You, before you used Git 😄


---

_**Documentation Maintained By:** Raymond C. Turner_

_**Date: October 26th, 2025**_
