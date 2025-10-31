#!/usr/bin/env bash
# batch_identify_to_csv.sh
# Usage: sudo ./batch_identify_to_csv.sh ips.txt
# ips.txt: one IP or CIDR per line (CIDRs will be expanded via nmap -sn discovery)
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

OUTDIR="batch_scan_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTDIR"
DISCOVERED="$OUTDIR/discovered.tmp"

# Expand/Discover live hosts from file (handle IPs and CIDRs)
> "$DISCOVERED"
while read -r line; do
  [ -z "$line" ] && continue
  echo "Discovering from: $line"
  sudo nmap -sn "$line" -oG - | awk '/Up$/{print $2}' >> "$DISCOVERED"
done < "$INPUT_FILE"
sort -u "$DISCOVERED" -o "$DISCOVERED"

if [ ! -s "$DISCOVERED" ]; then
  echo "No live hosts discovered. Exiting."
  exit 0
fi

CSV="$OUTDIR/summary.csv"
echo "ip,hostname,mac,vendor,open_ports,services,os,nmap_base" > "$CSV"

COMMON_PORTS="22,23,53,67,68,80,443,139,445,1900,5353,8000,8080,8443"

while read -r ip; do
  [ -z "$ip" ] && continue
  safe="${ip//\//_}"
  base="$OUTDIR/scan_$safe"
  echo "Scanning $ip ..."
  sudo nmap -sS -p "$COMMON_PORTS" -T4 -sV --version-light -O --osscan-guess \
    --script=banner,mdns-discovery -oA "$base" "$ip" >/dev/null 2>&1 || true

  # Parse .nmap file for fields. Use safe fallbacks when items not present.
  nmapfile="$base.nmap"
  hostname=""
  mac=""
  vendor=""
  open_ports=""
  services=""
  os=""
  if [ -f "$nmapfile" ]; then
    # Hostname line (Nmap scan report for ...)
    hostline=$(grep "^Nmap scan report for" "$nmapfile" | head -n1 || true)
    if [ -n "$hostline" ]; then
      # If line like: Nmap scan report for pi.hole (192.168.1.104)
      if echo "$hostline" | grep -q "("; then
        hostname=$(echo "$hostline" | sed -E 's/^Nmap scan report for ([^(]+) \(.*/\1/;s/^[[:space:]]+//;s/[[:space:]]+$//')
      else
        # otherwise may be: Nmap scan report for 192.168.1.80
        hostname=""
      fi
    fi

    # MAC Address line
    macline=$(grep -i "MAC Address:" "$nmapfile" || true)
    if [ -n "$macline" ]; then
      mac=$(echo "$macline" | awk -F' ' '{print $3}')
      vendor=$(echo "$macline" | sed -E 's/.*\(([^\)]+)\).*/\1/' || true)
    fi

    # Open ports & services: lines like "22/tcp   open  ssh  OpenSSH ..."
    open_ports=$(awk '/^PORT/{flag=1;next} /^Host script results:/{flag=0} flag' "$nmapfile" | awk 'NF{print $1}' | paste -s -d';' - || true)
    # services = port:service/version semi-colon separated
    services=$(awk '/^PORT/{flag=1;next} /^Host script results:/{flag=0} flag' "$nmapfile" | awk 'NF{print $1 ":" $3 ( ($4) ? "/" $4 : "") }' | paste -s -d';' - || true)
    # OS:
    os=$(grep -i "OS details:" "$nmapfile" | sed -E 's/OS details: //I' | head -n1 || true)
    if [ -z "$os" ]; then
      os=$(grep -i "OS guesses:" "$nmapfile" | sed -E 's/OS guesses: //I' | head -n1 || true)
    fi
  fi

  # Escape CSV fields (simple escaping: wrap in double quotes and escape inner quotes)
  csv_escape() {
    echo "\"$(echo "$1" | sed 's/"/""/g')\""
  }

  echo "$(csv_escape "$ip"),$(csv_escape "$hostname"),$(csv_escape "$mac"),$(csv_escape "$vendor"),$(csv_escape "$open_ports"),$(csv_escape "$services"),$(csv_escape "$os"),$(csv_escape "$base")" >> "$CSV"
done < "$DISCOVERED"

echo "Done. Summary CSV: $CSV"
echo "Raw per-host nmap outputs in $OUTDIR (scan_* files)."

