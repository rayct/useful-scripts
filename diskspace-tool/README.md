A **complete, production-ready bundle** that includes:

1. A **universal Python script** (`diskspace.py`)
2. A **standalone Bash script** (`diskspace.sh`)
3. A **README.md** that explains usage for all platforms

You can copy this whole bundle into a folder named `diskspace-tool/`.

---

## 🐍 **diskspace.py**

```python
#!/usr/bin/env python3
"""
diskspace.py — Cross-platform disk usage viewer
Author: rwxray
"""

import os
import platform
import shutil
import psutil
import subprocess

def human_readable(size):
    for unit in ['B','KB','MB','GB','TB']:
        if size < 1024:
            return f"{size:.2f} {unit}"
        size /= 1024

def windows_disk_info():
    print("=== Disk Space (Windows) ===\n")
    for part in psutil.disk_partitions(all=False):
        usage = psutil.disk_usage(part.mountpoint)
        print(f"Drive: {part.device}")
        print(f"  File System: {part.fstype}")
        print(f"  Total: {human_readable(usage.total)}")
        print(f"  Used : {human_readable(usage.used)}")
        print(f"  Free : {human_readable(usage.free)}")
        print(f"  Used %: {usage.percent}%\n")

def unix_disk_info():
    print("=== Mounted Filesystems ===\n")
    try:
        subprocess.run(["df", "-hT"], check=True)
    except Exception:
        print("Could not run df -hT; falling back to psutil.\n")
        for part in psutil.disk_partitions(all=False):
            usage = psutil.disk_usage(part.mountpoint)
            print(f"{part.device:<20} {part.fstype:<8} "
                  f"{human_readable(usage.total):>10} total, "
                  f"{human_readable(usage.used):>10} used, "
                  f"{human_readable(usage.free):>10} free "
                  f"({usage.percent:>5.1f}%) at {part.mountpoint}")
    print("\n=== Block Devices ===\n")
    subprocess.run(["lsblk", "-o", "NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL"], check=False)

def main():
    os_type = platform.system()
    print(f"Detected OS: {os_type}\n")
    if os_type == "Windows":
        windows_disk_info()
    elif os_type in ("Linux", "Darwin"):
        unix_disk_info()
    else:
        print("Unsupported OS. Please run on Windows, Linux, or macOS.")

if __name__ == "__main__":
    main()
```

---

## 🐧 **diskspace.sh**

```bash
#!/bin/bash
# diskspace.sh — Simple disk space viewer for Linux/macOS
# Author: rwxray

echo "=== Disk Space Usage ==="
df -h --output=source,fstype,size,used,avail,pcent,target | column -t

echo ""
echo "=== Block Devices ==="
if command -v lsblk &>/dev/null; then
    lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL | column -t
else
    echo "lsblk not available on this system."
fi

echo ""
echo "=== Mounted Partitions (psutil-style fallback) ==="
for mount in $(mount | awk '{print $3}'); do
    if [ -d "$mount" ]; then
        used=$(df -h "$mount" | awk 'NR==2 {print $3}')
        avail=$(df -h "$mount" | awk 'NR==2 {print $4}')
        perc=$(df -h "$mount" | awk 'NR==2 {print $5}')
        echo "$mount  used: $used, avail: $avail ($perc)"
    fi
done
```

Make it executable:

```bash
chmod +x diskspace.sh
```

Run:

```bash
./diskspace.sh
```

---

## 📘 **README.md**

````markdown
# 🧠 DiskSpace Tool

A lightweight, cross-platform toolkit to view disk usage across **Windows**, **Linux**, and **macOS**.

---

## 📦 Contents

- `diskspace.py` — Python script that auto-detects OS and displays disk info.
- `diskspace.sh` — Shell script for Linux/macOS users.
- `README.md` — Documentation and usage guide.

---

## 🚀 Usage

### 🔹 Linux / macOS

#### Option 1 — Run the Bash Script
```bash
chmod +x diskspace.sh
./diskspace.sh
````

#### Option 2 — Run the Python Script

```bash
python3 diskspace.py
```

> ✅ Requires `psutil`:
>
> ```bash
> pip install psutil
> ```

---

### 🔹 Windows

Run the Python script in **PowerShell**:

```powershell
python diskspace.py
```

Output includes:

* Drive letter
* Filesystem type
* Total, used, and free space (in GB)
* Usage percentage

---

## 🧩 Example Output

**Linux/macOS**

```
=== Mounted Filesystems ===
Filesystem     Type     Size  Used  Avail  Use%  Mounted on
/dev/sda1      ext4      50G   12G    36G   25%  /
/dev/sdb1      ext4     200G  100G   100G   50%  /mnt/data
```

**Windows**

```
Drive: C:\
  File System: NTFS
  Total: 475.00 GB
  Used : 200.00 GB
  Free : 275.00 GB
  Used %: 42%
```

---

## 🧑‍💻 Requirements

* **Python 3.7+**
* **psutil** (`pip install psutil`)
* Optional: `lsblk`, `df` (Linux/macOS utilities)

---

## 🏁 Notes

* The Python script auto-detects your OS and uses appropriate tools.
* The Bash script provides a native, dependency-free option for Unix-like systems.

---

**Author:** rwxray
**License:** MIT

