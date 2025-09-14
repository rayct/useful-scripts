# Bluetooth Battery Status Script

A simple Bash script to monitor and log **Bluetooth device battery levels** on Linux.

---

## 🔹 Features

* Logs **connected Bluetooth devices** battery levels.
* JSON and CSV logs are **always generated**, no flags needed.
* Optional flags:

  * `--all` → include all paired devices
  * `--verbose` → include devices with no battery info
* Pretty table output to console.
* Compatible with Python plotting script for historical analysis.
* Logs use **UK/GB local time** (`DD-MM-YYYY, HH:MM:SS±TZ`).

---

## 🔹 Log Locations

* **JSON (NDJSON)**: `logs/json/bt-battery-log.json`

  * Each line is a complete JSON object representing a single logging event.
  * Example entry:

```json
{"timestamp":"14-09-2025, 10:14:24+01:00","devices":[{"name":"MX Keys Mac","mac":"FE:12:51:4D:4C:32","battery":"50%"}]}
```

* **CSV**: `logs/csv/bt-battery-log.csv`

  * Timestamp and device info separated by commas.
  * Example entry:

```
14-09-2025, 10:14:24+01:00,MX Keys Mac,FE:12:51:4D:4C:32,50%
```

> **Note:** The JSON log is **newline-delimited (NDJSON)**, not a single JSON array. This allows **safe appending** of entries without rewriting the file. Most tools, including the provided Python plotting script, parse it line by line without issues.

---

## 🔹 Usage

```bash
# Default run (logs JSON + CSV)
./bt-battery.sh

# Include all paired devices
./bt-battery.sh --all

# Include devices with no battery info
./bt-battery.sh --verbose
```

---

## 🔹 Automatic Logging with systemd

The project includes an **installation script** that sets up the systemd service and timer automatically.

### Installation Script

`install-bt-battery-systemd.sh`:

```bash
chmod +x install-bt-battery-systemd.sh
./install-bt-battery-systemd.sh
```

This script will:

1. Copy `bt-battery.service` and `bt-battery.timer` to `~/.config/systemd/user/`.
2. Reload the user systemd daemon.
3. Enable and start the timer automatically.
4. Run the logger every 30 minutes and 5 minutes after boot.

### Manual systemd Setup (Optional)

**Service file:** `systemd/bt-battery.service`

```ini
[Unit]
Description=Log Bluetooth battery levels (JSON + CSV)

[Service]
Type=oneshot
ExecStart=/bin/bash /path/to/bt-battery.sh
```

**Timer file:** `systemd/bt-battery.timer`

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

Enable and start manually:

```bash
systemctl --user daemon-reload
systemctl --user enable bt-battery.timer
systemctl --user start bt-battery.timer
```

---

## 🔹 Python Plotting Script

The project includes `bt-battery-plot.py`, which **merges JSON and CSV logs** and plots historical battery levels for all devices.

### Features

* Reads **NDJSON (`logs/json/bt-battery-log.json`)** and **CSV (`logs/csv/bt-battery-log.csv`)** logs.
* Merges all entries into a single dataset.
* Groups data by device and plots battery percentage over time.
* UK/GB timestamps from the logs are used on the X-axis.
* Ignores malformed or incomplete log entries.
* Generates a clean line plot with markers for each device.

### Usage

```bash
python3 bt-battery-plot.py
```

---

## 🔹 Importing CSV into Excel / LibreOffice

* Open `logs/csv/bt-battery-log.csv`.
* Use comma (,) as separator.
* View timestamped battery history.

---

## 🔹 Notes

* Not all devices report battery levels.
* JSON and CSV logs are **timestamped with UK/GB time**.
* NDJSON format allows safe appending and fast logging.
* The Python plotting script handles both JSON and CSV logs simultaneously.
* The installation script simplifies systemd setup to **one command**.

---

## 🔹 License

MIT License.

---

This README now fully covers:

* NDJSON vs CSV logging
* UK/GB timestamps
* Python plotting functionality
* Automatic systemd installation
* Usage instructions and examples

Everything is documented to match all current scripts and project structure.


---

Documentation By: Raymond C. Turner

Date: September 14th, 2025

