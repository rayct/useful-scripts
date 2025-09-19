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

## 🔹 Global Installation

You can install the script globally so it’s accessible system-wide as `bt-battery`.

### Option 1: Using Makefile

```bash
make install
```

This will:

* Copy `bt-battery.sh` → `/usr/local/bin/bt-battery`
* Set correct permissions (`755`)
* Set ownership (`root:root`)

Uninstall with:

```bash
make uninstall
```

### Option 2: Using Installer Script

```bash
chmod +x install-bt-battery-global.sh
./install-bt-battery-global.sh
```

This script installs `bt-battery.sh` into `/usr/local/bin/` with the correct permissions.

After installation, simply run:

```bash
bt-battery
```

from anywhere.

---

## 🔹 Automatic Logging with systemd

The project includes an **installation script** that sets up the systemd service and timer automatically.

### Installation Script

```bash
chmod +x install-bt-battery-systemd.sh
./install-bt-battery-systemd.sh
```

This script will:

1. Copy `bt-battery.service` and `bt-battery.timer` to `~/.config/systemd/user/`.
2. Reload the user systemd daemon.
3. Enable and start the timer automatically.
4. Run the logger every 30 minutes and 5 minutes after boot.

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

## 🔹 Developer Notes & Contribution

### Project Structure

```
bt-battery/
├── bt-battery.sh                # Main logger script
├── bt-battery-plot.py           # Python plotting script
├── logs/                        # JSON + CSV logs stored here
│   ├── json/
│   └── csv/
├── systemd/                     # systemd service + timer
├── Makefile                     # Global installer
├── install-bt-battery-global.sh # Alternate global installer
├── install-bt-battery-systemd.sh# systemd setup helper
├── README.md
└── .gitignore
```

### Contributing

1. Fork the repo and create a feature branch:

   ```bash
   git checkout -b feature/my-change
   ```
2. Make changes, update docs/tests if needed.
3. Run linting (e.g., `shellcheck bt-battery.sh` for Bash, `flake8` for Python).
4. Submit a pull request with a clear description.

### Debugging Tips

* Run `bt-battery.sh --verbose` to include all devices, even without battery info.
* Check systemd logs with:

  ```bash
  journalctl --user -u bt-battery.service
  ```
* Validate NDJSON logs with:

  ```bash
  jq . logs/json/bt-battery-log.json
  ```
* If plotting fails, verify dependencies:

  ```bash
  pip install matplotlib
  ```

### Roadmap Ideas

* Add support for exporting to SQLite or InfluxDB.
* Create a web-based dashboard for real-time battery monitoring.
* Add notifications (e.g., low battery alerts).

---

## 🔹 License

MIT License.

---

README covers:

* Installation (local + global)
* Logging & plotting
* systemd setup (manual + auto)
* Developer guide (contribution, debugging, roadmap)


---

Documentation By: Raymond C. Turner

Date: September 19th, 2025

