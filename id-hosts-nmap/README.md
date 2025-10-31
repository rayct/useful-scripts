## 1) Full-port batch script — `batch_identify_fullport_to_csv.sh`

Save this as `batch_identify_fullport_to_csv.sh`, make executable `chmod +x batch_identify_fullport_to_csv.sh`, and run with `sudo`:

```bash
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
```

**Important notes about the script**

* It performs `nmap -p-` (all TCP ports), `-sS` (SYN scan), `-sV`/`--version-all` (service/version detection), and `-O` (OS detection). Very noisy — expect long runtimes for many hosts.
* The script first runs `nmap -sn` to discover live hosts from each line in `ips.txt` (so CIDRs and lists work).
* Outputs:

  * `summary.csv` with columns:

    * `ip,hostname,mac,vendor,open_ports,services,os,nmap_base,scan_flags`
  * Per-host `scan_<ip>.*` (`.nmap`, `.gnmap`, `.xml`) files in the output directory.
* Run as `sudo` for SYN scans and best OS detection. If you cannot run as root, change `-sS` to `-sT`.

---

## 2) README.md — full guide for all scripts

Save the following as `README.md` alongside your scripts.

# Network Identification & Batch Scanning Toolkit

**Purpose:** a collection of scripts to discover devices on a local LAN, identify Raspberry Pis and other hardware via MAC OUI/hostnames/mDNS/Open services, and produce machine-readable summaries (CSV).  
**Important:** these tools perform network scanning. Use **only** on networks and devices you own or have explicit permission to test.

---

## Contents

- `reduced_noise_identify.sh` — conservative scan of common informative ports (Linux/macOS).
- `aggressive_identify.sh` — per-host full-port scan variant for a single host (previously provided).
- `batch_identify_to_csv.sh` — batch scanner that scans common ports and writes `summary.csv` (CSV).
- `batch_identify_fullport_to_csv.sh` — **FULL-PORT** variant (all TCP ports) — **very noisy** and slow.
- `win_batch_identify.ps1` — PowerShell batch scanner for Windows (scans common ports, writes CSV).
- `win_aggressive_identify.ps1` — (previously provided) per-host aggressive scans for Windows (adjustable).
- `README.md` — this guide.

---

## Quick safety & etiquette

- **Run only on networks you control** or have explicit written permission to test.
- Full-port scans (`-p-`) with `-sS`/`--version-all` and `-O` are noisy and may trigger alerts on routers/IDS/managed networks — use `-T` and `--min-rate` thoughtfully.
- If you need quieter scans: use `--version-light`, `-T3`, `-sT` (instead of `-sS`), and restrict ports to common informative ports (see `COMMON_PORTS` in scripts).
- Log and keep results private. Scanning other people's networks without consent may be illegal.

---

## Installation / prerequisites

- Linux/macOS:
  - `nmap` (recommended from distribution packages or Homebrew on macOS: `brew install nmap`)
  - `sudo` for SYN scans and MAC/OS detection
  - (optional) `avahi-utils` on Linux for `avahi-resolve` / mDNS interaction
- Windows:
  - Install Npcap and Nmap for Windows. Run PowerShell as Administrator for `-sS` scans.

---

## Usage examples

### A) Reduced-noise scan (quick, safer)
```bash
sudo ./reduced_noise_identify.sh 192.168.1.0/24
# or
sudo ./reduced_noise_identify.sh 192.168.1.80
````

Outputs per-host `nmap` files in `reduced_scan_YYYYMMDD_HHMMSS/`.

### B) Batch scan -> CSV (common ports)

Prepare `ips.txt` (one IP or CIDR per line), then:

```bash
sudo ./batch_identify_to_csv.sh ips.txt
# Output: batch_scan_YYYYMMDD_HHMMSS/summary.csv
```

### C) Full-port batch scan -> CSV (noisy)

```bash
sudo ./batch_identify_fullport_to_csv.sh ips.txt
# Output: batch_fullport_scan_YYYYMMDD_HHMMSS/summary.csv
```

### D) Windows PowerShell (Admin) — common ports

Open PowerShell as Administrator:

```powershell
.\win_batch_identify.ps1 -InputFile .\ips.txt -OutDir .\out
```

---

## CSV format (`summary.csv`)

Columns (consistent across batch scripts; fields may be empty if not detected):

* `ip` — target IPv4 address
* `hostname` — reverse-resolved hostname (if present in nmap output)
* `mac` — MAC address (if discoverable on local LAN)
* `vendor` — MAC OUI vendor (from nmap MAC line)
* `open_ports` — semicolon-separated list of port numbers + protocol (e.g., `22/tcp;80/tcp`)
* `services` — semicolon-separated `port:service/version` entries (best-effort)
* `os` — OS details or top OS guess (from nmap)
* `nmap_base` — base filename of the per-host nmap outputs in the output folder
* `scan_flags` — the nmap flags used for that run (useful for auditing run parameters)

---

## How the scripts identify Raspberry Pis

* **MAC OUI**: Raspberry Pi Foundation OUIs commonly include `B8:27:EB`, `DC:A6:32`, `E4:5F:01`, etc. A matching vendor is a strong signal.
* **mDNS / Hostname**: many Pis use `raspberrypi` or `pi.*` hostnames via mDNS (`.local`) — scripts run `mdns-discovery` to capture those where advertised.
* **Open services**: OpenSSH (`22/tcp`) plus Linux service banners are common on Pis.
* Use a combination of MAC OUI + hostname + service/banner for confidence.

---

## Making scans quieter

* Replace `-sS` with `-sT` (no raw sockets, works without sudo, but more chatty to target OS).
* Remove `-p-` and scan a curated list of common ports (see `COMMON_PORTS` in scripts).
* Use `--version-light` instead of `--version-all`.
* Use `-T3` instead of `-T4` and avoid `--min-rate` or high parallelism.

---

## Performance & resource tips

* Full-port scans across many hosts are slow: consider scanning fewer hosts in parallel or using `--min-rate` to tune throughput. Beware that increasing rate increases noise.
* For large networks, split `ips.txt` into chunks and run scans during maintenance windows.

---

## Troubleshooting

* **No MACs shown**: ensure you run nmap on a machine on the same layer-2 network and use `sudo` (or run `arp -a` / `ip neigh`).
* **Nmap permission errors**: run as root / Administrator for SYN scans. If not possible, change to `-sT`.
* **Long runtimes**: reduce to `COMMON_PORTS` or use `--top-ports N` instead of `-p-`.
* **False positives or strange banners**: inspect per-host `.nmap`/`.xml` files in the output folder for full context.
* **Windows path issues for nmap**: set `$nmapPath` in PowerShell scripts or add nmap to PATH.

---

## Example troubleshooting workflows

* Confirm MAC/OUI vendor:

  ```bash
  arp -an | grep 192.168.1.80
  # or
  ip neigh show 192.168.1.80
  ```
* Re-run a focused banner scan on one IP:

  ```bash
  sudo nmap -sS -p 22,80,443 -sV --version-light --script=banner,mdns-discovery -oA focused_192_168_1_80 192.168.1.80
  ```

---

## Converting CSV -> JSON (one-liner)

If you want JSON instead of CSV (Linux/macOS with `jq`):

```bash
csvfile="batch_scan_YYYYMMDD_HHMMSS/summary.csv"
tail -n +2 "$csvfile" | \
awk -F',' '{
  ip=$1; hostname=$2; mac=$3; vendor=$4; open=$5; services=$6; os=$7; base=$8; flags=$9;
  gsub(/^"|"$/,"",ip); gsub(/^"|"$/,"",hostname); gsub(/^"|"$/,"",mac); gsub(/^"|"$/,"",vendor);
  gsub(/^"|"$/,"",open); gsub(/^"|"$/,"",services); gsub(/^"|"$/,"",os); gsub(/^"|"$/,"",base); gsub(/^"|"$/,"",flags);
  printf "{\"ip\":%s,\"hostname\":%s,\"mac\":%s,\"vendor\":%s,\"open_ports\":%s,\"services\":%s,\"os\":%s,\"nmap_base\":%s,\"scan_flags\":%s}\n", \
    "\""ip"\"", "\""hostname"\"", "\""mac"\"", "\""vendor"\"", "\""open"\"", "\""services"\"", "\""os"\"", "\""base"\"", "\""flags"\""
}' | jq -s .
```

(If you prefer, I can provide a proper CSV->JSON script that robustly handles embedded commas/quotes.)

---

## Examples / Quick scenarios

* **Find Raspberry Pis fast**:

  1. `sudo arp-scan --localnet` (fast OUI lookup; requires `arp-scan`).
  2. `sudo nmap -sn 192.168.1.0/24` (capture MACs/hostnames).
  3. Use `batch_identify_to_csv.sh` (conservative) or `batch_identify_fullport_to_csv.sh` (full-port) on the discovered IPs.

* **If you only have Windows**: run `win_batch_identify.ps1` as Administrator with `ips.txt`.

---

## FAQs

**Q: Will this find devices behind another subnet or NAT?**
A: No — MAC OUI and ARP are limited to the local layer-2 network. For devices behind routers/NAT, you can only see their external addresses and open ports.

**Q: Can these scripts discover devices using IPv6?**
A: Not directly — they are written for IPv4. You can adapt to IPv6; nmap supports IPv6 scanning but discovery and MAC capture differ.

**Q: Can I change output to include timestamped logs?**
A: Yes — modify the script to append timestamps to CSV lines (e.g., add `$(date -Iseconds)` when writing rows). I can add that variant if you want.

