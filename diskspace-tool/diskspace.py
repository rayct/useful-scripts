#!/usr/bin/env python3
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

