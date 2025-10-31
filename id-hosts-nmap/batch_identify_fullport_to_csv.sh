#!/usr/bin/env bash
# batch_identify_fullport_to_csv.sh
# Full-port batch scanner -> summary CSV
# WARNING: Very noisy and slow. Use only on networks/devices you own or have explicit permission to test.
# Usage: sudo ./batch_identify_fullport_to_csv.sh ips.txt
# ips.txt: one IP or CIDR per line (CIDRs will be expanded via nmap -sn)
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: sudo $0 ips.txt"
  exit 2
fi

INPUT_FILE="$1"
if [ ! -f "$INPUT_FILE" ]; then
  echo "File $INPUT_FILE not found."
  exit 2
fi

OUTDIR="batch_fullport_scan_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"
DISCOVERED="$OUTDIR/discovered.tmp"

echo "Starting full-port batch scan"
echo "Output directory: $OUTDIR"
echo

# 0) Discover live hosts from each line in input (handles single IPs and CIDRs)
> "$DISCOVERED"
while read -r line || [ -n "$line" ]; do
  line="${line%%#*}" # strip comments after #
  line="${line//[[:space:]]/}" # trim whitespace
  [ -z "$line" ] && continue
  echo "Discovering live hosts from: $line"
  # -sn discovery; we capture the IPv4 addresses of alive hosts
  sudo nmap -sn "$line" -oG - | awk '/Up$/{print $2}' >> "$DISCOVERED"
done < "$INPUT_FILE"
sort -u "$DISCOVERED" -o "$DISCOVERED"

if [ ! -s "$DISCOVERED" ]; then
  echo "No live hosts discovered. Exiting."
  exit 0
fi

CSV="$OUTDIR/summary.csv"
echo "ip,hostname,mac,vendor,open_ports,services,os,nmap_base,scan_flags" > "$CSV"

# Full-port scan flags — adjust if you need less/noisier behavior.
NMAP_FLAGS="-sS -p- -T4 -sV --version-all -O --osscan-guess --reason --script=banner,mdns-discovery"

echo "Discovered hosts:"
cat "$DISCOVERED"
echo
echo "Starting full-port scans using nmap flags:"
echo "$NMAP_FLAGS"
echo

# Scan each discovered host
while read -r ip; do
  [ -z "$ip" ] && continue
  safe="${ip//\//_}"
  base="$OUTDIR/scan_$safe"
  echo "Scanning $ip (output -> $base.*) ..."
  # Run nmap (suppress streaming output to keep console readable)
  sudo nmap $NMAP_FLAGS -oA "$base" "$ip" >/dev/null 2>&1 || true

  nmapfile="$base.nmap"
  hostname=""
  mac=""
  vendor=""
  open_ports=""
  services=""
  os=""

  if [ -f "$nmapfile" ]; then
    # Hostname (if present) — handle "Nmap scan report for name (ip)" case
    hostline=$(grep "^Nmap scan report for" "$nmapfile" | head -n1 || true)
    if [ -n "$hostline" ]; then
      if echo "$hostline" | grep -q "("; then
        hostname=$(echo "$hostline" | sed -E 's/^Nmap scan report for ([^(]+) \(.*/\1/' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
      else
        hostname=""
      fi
    fi

    macline=$(grep -i "MAC Address:" "$nmapfile" || true)
    if [ -n "$macline" ]; then
      mac=$(echo "$macline" | awk '{print $3}')
      vendor=$(echo "$macline" | sed -E 's/.*\(([^\)]+)\).*/\1/' || true)
    fi

    # Open ports: collect port numbers as semicolon-separated list
    open_ports=$(awk '/^PORT/{flag=1;next} /^Host script results:/{flag=0} flag' "$nmapfile" | awk 'NF{print $1}' | paste -s -d';' - || true)
    # Services: produce port:service/version entries semi-colon separated
    services=$(awk '/^PORT/{flag=1;next} /^Host script results:/{flag=0} flag' "$nmapfile" | awk 'NF{
        port=$1; service=$3; ver=""
        if (NF>=4) {
          ver=$4
          for (i=5;i<=NF;i++) ver=ver" "$i
        }
        gsub(/,/,"; ",ver)
        print port":"service"/"ver
    }' | paste -s -d';' - || true)

    os=$(grep -i "OS details:" "$nmapfile" | sed -E 's/OS details: //I' | head -n1 || true)
    if [ -z "$os" ]; then
      os=$(grep -i "OS guesses:" "$nmapfile" | sed -E 's/OS guesses: //I' | head -n1 || true)
    fi
  fi

  # Simple CSV escape
  csv_escape() {
    echo "\"$(echo "$1" | sed 's/"/""/g')\""
  }

  echo "$(csv_escape "$ip"),$(csv_escape "$hostname"),$(csv_escape "$mac"),$(csv_escape "$vendor"),$(csv_escape "$open_ports"),$(csv_escape "$services"),$(csv_escape "$os"),$(csv_escape "$base"),$(csv_escape "$NMAP_FLAGS")" >> "$CSV"

done < "$DISCOVERED"

echo
echo "Full-port batch scan complete."
echo "Summary CSV: $CSV"
echo "Per-host nmap outputs: $OUTDIR/scan_*"
echo
echo "IMPORTANT: Full-port scans can be slow and generate hundreds/thousands of probes per host. If you need a quieter run, consider reducing to common ports or using --min-rate and -T3 or replacing -sS with -sT."

