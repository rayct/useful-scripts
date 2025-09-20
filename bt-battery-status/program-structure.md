## 1 Directory Structure

```
bt-battery/
├── bt-battery.sh
├── bt-battery-plot.py
├── logs/
│   ├── csv/          # CSV logs (auto-created)
│   └── json/         # NDJSON logs (auto-created)
├── systemd/
│   ├── bt-battery.service
│   └── bt-battery.timer
├── README.md
└── .gitignore
```

---

## 2 bt-battery.sh

* Valid JSON output (NDJSON).
* CSV logging.
* Pretty table.
* UK/GB timestamp in `DD-MM-YYYY, HH:MM:SS±TZ`.
* Supports `--all` and `--verbose`.

*(Use the latest full script I provided earlier with the fixed JSON and UK/GB timestamp.)*

---

## 3 bt-battery-plot.py

* Reads **NDJSON and CSV**.
* Merges logs into one dataset.
* Plots historical battery levels.
* UK/GB timestamps on the X-axis.

*(Use the full Python script you provided, which merges JSON + CSV.)*

---

## 4 systemd/bt-battery.service

```ini
[Unit]
Description=Log Bluetooth battery levels (JSON + CSV)

[Service]
Type=oneshot
ExecStart=/bin/bash /path/to/bt-battery.sh
```

> Replace `/path/to/bt-battery.sh` with the absolute path to your script.

---

## 5 systemd/bt-battery.timer

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

## 6 README.md

* Fully updated to reflect **NDJSON**, **CSV**, **UK/GB timestamps**, **systemd**, and **Python plotting script**.
* Matches the current scripts and project behavior.

---

## 7 .gitignore

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

## 8 Creating the ZIP Archive

From the parent directory:

```bash
zip -r bt-battery.zip bt-battery/
```

* Includes all scripts, directories, systemd files, README.md, and `.gitignore`.
* Fully plug-and-play.

---

This package now contains everything:

* NDJSON + CSV logging
* Fixed JSON syntax
* UK/GB timestamps
* Python plotting script
* Systemd timer setup
* Updated README.md and .gitignore

You can unzip and start logging immediately.

---

Documentation By: Raymond C. Turner

Date: September 19th, 2025