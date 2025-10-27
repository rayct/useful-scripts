# checkproc — Verify Running Process Integrity

A lightweight utility to identify, verify, and validate running processes by PID on **Linux/macOS** and **Windows**.
It checks the executable path, file permissions, package origin, and SHA256 hash.
Optionally, it queries **VirusTotal** for known malware reports.

## Files
| File | Platform | Description |
|------|-----------|--------------|
| `checkproc.sh` | Linux/macOS | Bash script for `/proc`-based systems |
| `checkproc.ps1` | Windows | PowerShell script for process inspection |

## Installation

### Linux / macOS
```bash
sudo install -m 755 checkproc.sh /usr/local/bin/checkproc
```

### Windows
Save `checkproc.ps1` somewhere on your PATH, e.g. `C:\Tools\checkproc.ps1`.

## Usage

### Linux/macOS
```bash
checkproc 2134
```

### Windows
```powershell
.\checkproc.ps1 -Pid 2134
```

## VirusTotal Integration

Export your API key as an environment variable:

### Linux/macOS
```bash
export VT_API_KEY="your_api_key_here"
```

### Windows
```powershell
$env:VT_API_KEY = "your_api_key_here"
```

## License
MIT License
