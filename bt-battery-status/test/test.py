#!/usr/bin/env python3
import json, csv, matplotlib.pyplot as plt
from datetime import datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).parent
LOG_JSON = SCRIPT_DIR / "logs/json/bt-battery-log.json"
LOG_CSV = SCRIPT_DIR / "logs/csv/bt-battery-log.csv"

entries = []

# Read JSON logs if they exist
if LOG_JSON.exists():
    with open(LOG_JSON, "r") as f:
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

# Read CSV logs if they exist
if LOG_CSV.exists():
    with open(LOG_CSV, "r") as f:
        reader = csv.reader(f)
        for row in reader:
            if len(row) != 4: continue
            ts_str, name, mac, battery = row
            try:
                ts = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                battery = int(battery.rstrip("%"))
            except Exception: continue
            entries.append((name, ts, battery))

if not entries:
    raise FileNotFoundError("No valid JSON or CSV log entries found.")

# Group entries by device
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
plt.title("Bluetooth Device Battery Levels Over Time (Merged JSON + CSV)")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()
