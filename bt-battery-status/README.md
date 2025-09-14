An Overly Bloated CLI Bluetooth Device Battery Level Tool
Written in BASH and Python with the option to set a systemd service + timer to automatically log battery levels every 30 minutes 

---

````markdown
# Bluetooth Battery Status Script

A simple Bash script to check the **battery level of Bluetooth devices** (keyboards, mice, trackpads, headphones, etc.) on Linux using `bluetoothctl`.  

It supports:
- Listing **connected devices** (default)  
- Listing **all paired devices** (`--all`)  
- Showing/hiding devices that don’t report battery info (`--verbose`)  
- Output as:
  - **Pretty table** (default)  
  - **JSON** (`--json`) – structured, good for automation  
  - **CSV** (`--csv`) – spreadsheet friendly (Excel/LibreOffice)  
- Automatic logging with **systemd timers**  
- Visualization with **Python + matplotlib** (supports both JSON and CSV logs)  
- Logs are now stored in **script-relative directories** for portability  

---

## 🔧 Requirements

- Linux system with [BlueZ](http://www.bluez.org/) installed  
- `bluetoothctl` (comes with BlueZ)  
- `jq` (for parsing JSON logs, optional)  
- `systemd` (for scheduled logging, optional)  
- `python3` + `matplotlib` (for plotting history, optional)  

---

## 📦 Installation

Clone or copy the script to your system and make it executable:

```bash
chmod +x bt-battery.sh
````

Optionally move it into your `$PATH`:

```bash
sudo mv bt-battery.sh /usr/local/bin/bt-battery
```

---

## 🚀 Usage

### Table view (default)

```bash
bt-battery.sh
```

### JSON output

```bash
bt-battery.sh --json
```

### CSV output

```bash
bt-battery.sh --csv
```

> ✅ Logs are written to the following subdirectories relative to the script:
>
> * JSON logs: `logs/json/bt-battery-log.json`
> * CSV logs: `logs/csv/bt-battery-log.csv`

---

## ⚠️ Notes

* Not all devices report battery percentage!
* `bluetoothctl info` only reports battery for **connected devices**.
* Logs now include a **timestamp** for each entry.

---

## ⏱️ Automatic Logging with systemd

A **systemd service + timer** to automatically log battery levels every 30 minutes.

### 1. Systemd Service (JSON + CSV)

`~/.config/systemd/user/bt-battery.service`:

```ini
[Unit]
Description=Log Bluetooth battery levels (JSON + CSV)

[Service]
Type=oneshot
ExecStart=/bin/bash /path/to/bt-battery.sh --json --csv
```

* The Bash script automatically creates `logs/json` and `logs/csv` directories relative to the script.
* JSON logs go to `logs/json/bt-battery-log.json`.
* CSV logs go to `logs/csv/bt-battery-log.csv`.

### 2. Timer

`~/.config/systemd/user/bt-battery.timer`:

```ini
[Unit]
Description=Run Bluetooth battery logger every 30 minutes

[Timer]
OnBootSec=5m
OnUnitActiveSec=30m
Unit=bt-battery.service

[Install]
WantedBy=timers.target
```

Enable and start the timer:

```bash
systemctl --user daemon-reload
systemctl --user enable bt-battery.timer
systemctl --user start bt-battery.timer
```

---

## 📝 Log Formats

### JSON

```json
{
  "timestamp": "2025-08-29T14:30:00Z",
  "devices": [
    {"name": "MX Keys", "mac": "FE:12:51:4D:4C:32", "battery": "50%"},
    {"name": "Magic Trackpad", "mac": "AA:BB:CC:DD:EE:FF", "battery": "62%"}
  ]
}
```

### CSV

```
2025-08-29T14:30:00Z,MX Keys,FE:12:51:4D:4C:32,50%
2025-08-29T14:30:00Z,Magic Trackpad,AA:BB:CC:DD:EE:FF,62%
```

Columns: `timestamp,device name,MAC,battery`

---

## 📊 Working with Logs (JSON + jq)

### Pretty-print the latest JSON entry

```bash
tail -n 1 logs/json/bt-battery-log.json | jq
```

### Show battery levels grouped by timestamp

```bash
jq -r '.timestamp + " → " + ([.devices[] | "\(.name): \(.battery)"] | join(", "))' logs/json/bt-battery-log.json
```

### Extract history for one device

```bash
jq -r '. as $root | .devices[] | select(.name=="MX Keys") | "\($root.timestamp) \(.battery)"' logs/json/bt-battery-log.json
```

---

## 📈 Python Helper Script (JSON + CSV)

Plot battery history from either JSON or CSV logs.

Save as `bt-battery-plot.py`:

```python
#!/usr/bin/env python3
import json
import csv
import matplotlib.pyplot as plt
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent

LOG_JSON = SCRIPT_DIR / "logs/json/bt-battery-log.json"
LOG_CSV = SCRIPT_DIR / "logs/csv/bt-battery-log.csv"

if LOG_JSON.exists():
    log_file = LOG_JSON
    mode = "json"
elif LOG_CSV.exists():
    log_file = LOG_CSV
    mode = "csv"
else:
    raise FileNotFoundError("No log file found in 'logs/json' or 'logs/csv' directories.")

entries = []

if mode == "json":
    with open(log_file, "r") as f:
        for line in f:
            try:
                data = json.loads(line)
                ts = datetime.fromisoformat(data["timestamp"].replace("Z", "+00:00"))
                for dev in data["devices"]:
                    name = dev.get("name", "Unknown")
                    battery = dev.get("battery", "0%").rstrip("%")
                    try:
                        battery = int(battery)
                    except ValueError:
                        continue
                    entries.append((name, ts, battery))
            except json.JSONDecodeError:
                continue

elif mode == "csv":
    with open(log_file, "r") as f:
        reader = csv.reader(f)
        for row in reader:
            if len(row) != 4:
                continue
            ts, name, mac, battery = row
            try:
                ts = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                battery = int(battery.rstrip("%"))
            except Exception:
                continue
            entries.append((name, ts, battery))

# Group by device
devices = {}
for name, ts, battery in entries:
    devices.setdefault(name, []).append((ts, battery))

# Plot
plt.figure(figsize=(10, 6))
for name, values in devices.items():
    values.sort(key=lambda x: x[0])
    times, bats = zip(*values)
    plt.plot(times, bats, marker="o", label=name)

plt.xlabel("Time")
plt.ylabel("Battery %")
plt.title(f"Bluetooth Device Battery Levels Over Time ({mode.upper()} log)")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()
```

Run it:

```bash
python3 bt-battery-plot.py
```

> The script automatically detects whether JSON or CSV logs exist and plots the battery history.

---

## 📦 Importing CSV into Excel / LibreOffice

1. Open `logs/csv/bt-battery-log.csv`.
2. Choose **comma (,) as separator**.
3. You’ll see a table of timestamped battery history.

---

## 📝 License

MIT License.
Feel free to modify and share.

---

This README now reflects:

- Script-relative logging directories (`logs/json` and `logs/csv`)  
- Dual logging to JSON + CSV  
- Python plotting works automatically with either format  
- Systemd service calls the Bash script once and logs to both directories  

---

Documentation By: Raymond C. Turner
Date: September 14th, 2025

