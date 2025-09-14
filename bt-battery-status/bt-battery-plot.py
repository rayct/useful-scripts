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
