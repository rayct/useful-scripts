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

