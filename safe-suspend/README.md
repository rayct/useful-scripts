# Safe Suspend

A robust, user-friendly Linux suspend helper script that:
- Checks system readiness before suspend.
- Prompts the user: **“Do you want to suspend now?”**
- Attempts a normal suspend first.
- Logs potential inhibitor processes if suspend fails.
- Falls back to forced suspend (`systemctl suspend -i`).
- Notifies the user through desktop pop-ups.
- If suspend fails repeatedly, offers to reboot instead.

Designed for laptops and desktops where the “Suspend” option sometimes disappears or becomes inhibited (e.g., Cinnamon, GNOME, KDE).

---

## 🧩 Features

- 🧠 **Pre-suspend confirmation:** asks before actually suspending  
- ✅ Graceful → forced suspend fallback  
- 🧾 Logs potential blocking processes (e.g., Chrome, VLC, VMs)  
- 🔔 Desktop notifications for every stage  
- 🔁 Optional reboot prompt after repeated failures  
- 🪶 Lightweight and fully local — no background daemons needed  

---

## ⚙️ Requirements

Install the required tools for notifications and popups:

```bash
sudo apt install libnotify-bin zenity
````

---

## 📥 Installation

1. Save the script to `~/bin` (or another directory in your PATH):

   ```bash
   mkdir -p ~/bin
   cp safe-suspend.sh ~/bin/safe-suspend.sh
   chmod +x ~/bin/safe-suspend.sh
   ```

2. (Optional) Add `~/bin` to your PATH if needed:

   ```bash
   echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```
   
3. Test it:

   ```bash
   ~/bin/safe-suspend.sh
   ```

---

## 🎛️ Create a Keyboard Shortcut

For Cinnamon, GNOME, or KDE:

* **Command:**

  ```
  ~/bin/safe-suspend.sh
  ```
* **Suggested shortcut:** `Super + Shift + S`

This allows you to trigger safe suspend anytime, even if the GUI option is missing.

---

## 🧠 Behavior Overview

| Step                     | Description                                                          |
| ------------------------ | -------------------------------------------------------------------- |
| **1. Pre-check**         | The script verifies system readiness.                                |
| **2. User confirmation** | A popup asks: *“System is ready. Do you want to suspend now?”*       |
| **3. Normal suspend**    | Tries `systemctl suspend`.                                           |
| **4. If fails**          | Logs inhibitors, retries with `systemctl suspend -i`.                |
| **5. If still fails**    | Increments failure counter (`~/.safe-suspend-fails`).                |
| **6. After 3 failures**  | Prompts the user: *“Suspend failed multiple times. Reboot instead?”* |
| **7. User decides**      | Either reboots or exits cleanly.                                     |

---

## 📄 Logging

Logs are written to:

```
~/safe-suspend.log
```

Example:

```
[2025-10-22 21:44:12] Initiating Safe Suspend...
[2025-10-22 21:44:17] Normal suspend failed. Checking inhibitors...
2160 cinnamon-sessio ray 01:12:45
[2025-10-22 21:44:19] Waiting 2 seconds, then forcing suspend...
```

The script also tracks consecutive failures in:

```
~/.safe-suspend-fails
```

---

## 🚨 Notifications

Safe Suspend uses desktop notifications (`notify-send`) and interactive dialogs (`zenity`) to guide you:

| Event                  | Popup Message                                      |
| ---------------------- | -------------------------------------------------- |
| System ready           | “Do you want to suspend now?”                      |
| Normal suspend attempt | “Attempting normal suspend...”                     |
| Forced suspend         | “Inhibitors logged. Forcing suspend in 2 seconds.” |
| Repeated failures      | “Suspend failed multiple times. Reboot instead?”   |
| Cancel                 | “Suspend canceled by user.”                        |

---

## 🧪 Manual Suspend Commands

You can test suspend manually:

```bash
systemctl suspend
```

Or to force it (ignoring inhibitors):

```bash
systemctl suspend -i
```

---

## 🧾 License

MIT License
(c) 2025 — Created by [rwxray](https://github.com/rwxray)

You are free to use, modify, and redistribute this script. Attribution appreciated!

---

## 💡 Future Enhancements

* Include **battery level** and **lid state** info in logs.
* Optional **pre-suspend safety checks** (e.g., disk I/O, temperature).
* Configurable thresholds for reboot prompt.
* Integration with system tray applets or power menus.


---


_**Documentation Maintained By:** Raymond C. Turner_

_**Date:** November 14th, 2025_
