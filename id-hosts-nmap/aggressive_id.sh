#!/usr/bin/env bash
# aggressive_identify.sh
# Aggressive identification: full TCP port scan, service/version detection, OS detection, mDNS probes.
# WARNING: Noisy. Use only on networks/devices you own or have explicit permission to scan.
# Usage: sudo ./aggressive_identify.sh 192.168.1.0/24
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: sudo $0 <subnet-or-ip> [<ip2> <ip3> ...]"
  exit 2
fi

TARGETS=("$@")
OUTDIR="aggressive_scan_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"
echo "Output -> $OUTDIR"
echo

# Step 0: quick discovery to reduce targets (fast ping/arp)
echo "Step 0: quick host discovery (this helps skip dead hosts)..."
DISCOVERED="$OUTDIR/discovered.txt"
sudo nmap -sn "${TARGETS[@]}" -oG - | awk '/Up$/{print $2}' | sort -u > "$DISCOVERED"
echo "Discovered hosts:"
cat "$DISCOVERED" || true
echo

if [ ! -s "$DISCOVERED" ]; then
  echo "No live hosts found. Exiting."
  exit 0
fi

# Step 1: aggressive per-host full-port scan
while read -r ip; do
  [ -z "$ip" ] && continue
  safeip=$(echo "$ip" | tr '/' '_')
  echo "---- Scanning $ip ----"
  base="$OUTDIR/scan_$safeip"

  # Full TCP SYN scan on all ports, service/version detection, OS detection, script probes for common discovery.
  # -T4: faster timing; --min-rate omitted to be moderately aggressive but not reckless.
  # --script=banner for grabbing banners where available; mdns-discovery can reveal mDNS names.
  sudo nmap -sS -p- --min-rate 1000 -T4 -sV --version-all -O --osscan-guess \
    --script=banner,mdns-discovery --reason -oA "$base" "$ip"

  # Extract concise summary: IP, MAC (if present), vendor, hostname, open ports+services
  echo "Summary for $ip:" > "$base.summary.txt"
  grep -i "^Nmap scan report for" "$base.nmap" -n || true
  # MAC line
  if grep -i "MAC Address" "$base.nmap" >/dev/null 2>&1; then
    grep -i "MAC Address" "$base.nmap" >> "$base.summary.txt"
  fi
  # Hostname / reverse DNS
  awk '/Nmap scan report for/{print; got=1} /PORT/{if(got) exit}' "$base.nmap" >> "$base.summary.txt" || true
  echo "Open ports & services:" >> "$base.summary.txt"
  awk '/PORT/{flag=1; next} /Host script results:/{flag=0} flag' "$base.nmap" | sed '/^$/d' >> "$base.summary.txt" || true

  echo "Saved: $base.*"
  echo
done < "$DISCOVERED"

echo "All scans finished. Summaries in $OUTDIR/*.summary.txt"
echo "Tip: inspect the raw $OUTDIR/*.nmap and $OUTDIR/*.gnmap files for full details."

