Perfect ✅ — here’s the full **ready-to-zip project structure** with the updated scripts, README.md, .gitignore, and systemd files. You can create the ZIP archive on your system and it will be plug-and-play.

---

## 1️⃣ Directory Structure

```
bt-battery/
├── bt-battery.sh
├── bt-battery-plot.py
├── logs/
│   ├── csv/          # CSV logs (auto-created)
│   └── json/         # JSON logs (auto-created)
├── systemd/
│   ├── bt-battery.service
│   └── bt-battery.timer
├── README.md
└── .gitignore
```

---

## 2️⃣ bt-battery.sh

```bash
#!/bin/bash
# bt-battery.sh
# Logs Bluetooth device battery levels in JSON and CSV

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR_JSON="$SCRIPT_DIR/logs/json"
LOG_DIR_CSV="$SCRIPT_DIR/logs/csv"

mkdir -p "$LOG_DIR_JSON" "$LOG_DIR_CSV"
LOG_FILE_JSON="$LOG_DIR_JSON/bt-battery-log.json"
LOG_FILE_CSV="$LOG_DIR_CSV/bt-battery-log.csv"

# Argument parsing
mode="Connected"
verbose=false
for arg in "$@"; do
    case $arg in
        --all) mode="Paired" ;;
        --verbose) verbose=true ;;
    esac
done

# Collect devices
devices=()
for dev in $(bluetoothctl devices $mode | awk '{print $2}'); do
    name=$(bluetoothctl info $dev | grep "Name:" | cut -d' ' -f2-)
    battery_raw=$(bluetoothctl info $dev | grep "Battery")
    if [[ -z "$battery_raw" ]]; then
        battery="No battery info"
    else
        if [[ "$battery_raw" =~ ([0-9]+)% ]]; then
            battery="${BASH_REMATCH[1]}%"
        elif [[ "$battery_raw" =~ \(([0-9]+)\) ]]; then
            battery="${BASH_REMATCH[1]}%"
        else
            battery="$battery_raw"
        fi
    fi
    if [[ "$battery" == "No battery info" && $verbose == false ]]; then
        continue
    fi
    devices+=("$name,$dev,$battery")
done

timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# JSON log
if [[ ${#devices[@]} -gt 0 ]]; then
    {
        echo -n "{\"timestamp\":\"$timestamp\",\"devices\":["
        for ((i=0; i<${#devices[@]}; i++)); do
            IFS=',' read -r name mac battery <<< "${devices[$i]}"
            if [[ $i -lt $(( ${#devices[@]} - 1 )) ]]; then
                echo -n "{\"name\":\"$name\",\"mac\":\"$mac\",\"battery\":\"$battery\"},"
            else
                echo -n "{\"name\":\"$name\",\"mac\":\"$mac\",\"battery\":\"$battery\"}"
            fi
        done
        echo "]}"
    } | tee -a "$LOG_FILE_JSON"
fi

# CSV log
for dev in "${devices[@]}"; do
    echo "$timestamp,$dev" | tee -a "$LOG_FILE_CSV"
done

# Pretty table
printf "%-25s %-20s %-10s\n" "Device Name" "MAC Address" "Battery"
printf "%-25s %-20s %-10s\n" "-----------" "-----------" "-------"
for dev in "${devices[@]}"; do
    IFS=',' read -r name mac battery <<< "$dev"
    printf "%-25s %-20s %-10s\n" "$name" "$mac" "$battery"
done
```

---

## 3️⃣ bt-battery-plot.py

```python
#!/usr/bin/env python3
import json, csv, matplotlib.pyplot as plt
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
                    try: battery = int(battery)
                    except ValueError: continue
                    entries.append((name, ts, battery))
            except json.JSONDecodeError:
                continue
elif mode == "csv":
    with open(log_file, "r") as f:
        reader = csv.reader(f)
        for row in reader:
            if len(row) != 4: continue
            ts, name, mac, battery = row
            try:
                ts = datetime.fromisoformat(ts.replace("Z", "+00:00"))
                battery = int(battery.rstrip("%"))
            except Exception: continue
            entries.append((name, ts, battery))

# Group by device
devices = {}
for name, ts, battery in entries:
    devices.setdefault(name, []).append((ts, battery))

# Plot
plt.figure(figsize=(10,6))
for name, values in devices.items():
    values.sort(key=lambda x:x[0])
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

---

## 4️⃣ systemd/bt-battery.service

```ini
[Unit]
Description=Log Bluetooth battery levels (JSON + CSV)

[Service]
Type=oneshot
ExecStart=/bin/bash /path/to/bt-battery.sh
```

> Replace `/path/to/bt-battery.sh` with absolute path.

---

## 5️⃣ systemd/bt-battery.timer

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

---

## 6️⃣ README.md

Use the **updated README.md** from the previous message (reflecting always-logged JSON + CSV).

---

## 7️⃣ .gitignore

```
# Ignore logs
logs/json/
logs/csv/

# Python cache
*.pyc
__pycache__/

# Editor/system files
.DS_Store
*.swp

# Temp logs
*.log
```

---

## 8️⃣ Creating the ZIP Archive

From the parent directory:

```bash
zip -r bt-battery.zip bt-battery/
```

✅ Result: `bt-battery.zip` contains the **complete, plug-and-play project** with logs, scripts, systemd files, README.md, and .gitignore.
