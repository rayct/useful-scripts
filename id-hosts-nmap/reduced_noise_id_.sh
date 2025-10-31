#!/usr/bin/env bash
# reduced_noise_identify.sh
# Conservative host identification: scans common informative ports only.
# Usage: sudo ./reduced_noise_identify.sh <ip-or-subnet-or-iplist>
# Example: sudo ./reduced_noise_identify.sh 192.168.1.80
# Example: sudo ./reduced_noise_identify.sh 192.168.1.0/24
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: sudo $0 <ip-or-subnet-or-iplist>"
  exit 2
fi

TARGETS=("$@")
OUTDIR="reduced_scan_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"
echo "Output -> $OUTDIR"
echo

# Common ports (informative but not full port sweep)
COMMON_PORTS="22,23,53,67,68,80,443,139,445,1900,5353,8000,8080,8443"

echo "Running quick discovery (ping/ARP-based) to find live hosts..."
sudo nmap -sn "${TARGETS[@]}" -oG "$OUTDIR/discovery.gnmap"
awk '/Up$/{print $2}' "$OUTDIR/discovery.gnmap" | sort -u > "$OUTDIR/discovered.txt"
echo "Discovered hosts:"
cat "$OUTDIR/discovered.txt" || true
echo

if [ ! -s "$OUTDIR/discovered.txt" ]; then
  echo "No live hosts found. Exiting."
  exit 0
fi

while read -r ip; do
  [ -z "$ip" ] && continue
  echo "---- $ip ----"
  base="$OUTDIR/scan_${ip//\//_}"
  # Conservative scan: common ports, version detection, minimal scripts
  sudo nmap -sS -p "$COMMON_PORTS" -T3 -sV --version-light -O --osscan-guess \
    --script=banner,mdns-discovery -oA "$base" "$ip"
  echo "Saved: $base.*"
  echo
done < "$OUTDIR/discovered.txt"

echo "Done. Results in $OUTDIR"

