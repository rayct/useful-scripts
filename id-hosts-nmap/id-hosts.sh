#!/usr/bin/env bash
# identify_hosts.sh  - quick probe for 3 hosts you saw
# Usage: sudo ./identify_hosts.sh

HOSTS=("192.168.1.80" "192.168.1.75" "192.168.1.104")

echo "Starting quick identification probes..."
echo

for ip in "${HOSTS[@]}"; do
  echo "---- $ip ----"
  # ARP / IP neighbor entry
  echo "ARP / neighbor:"
  ip neigh show "$ip" || arp -an | grep "$ip" || true
  echo

  # Ping once (get latency)
  echo "Ping:"
  ping -c 1 -W 1 "$ip" 2>/dev/null | sed -n '1,2p'
  echo

  # Fast service scan for common ports + banner
  echo "nmap (common ports + service detection, may take a few seconds):"
  sudo nmap -sS -sV -O --reason -p 22,23,53,67,68,80,443,1900,5353,8000,8080 "$ip" -oN - | sed -n '1,200p'
  echo

  # mDNS resolution if avahi-utils is installed
  if command -v avahi-resolve >/dev/null 2>&1; then
    echo "avahi-resolve:"
    avahi-resolve -a "$ip" || true
    echo
  fi

  # optional: try reverse DNS
  echo "reverse DNS (host):"
  host "$ip" 2>/dev/null || nslookup "$ip" 2>/dev/null || true
  echo
done

echo "Done."

