# Network Identification & Batch Scanning Toolkit

**Purpose:** a collection of scripts to discover devices on a local LAN, identify Raspberry Pis and other hardware via MAC OUI/hostnames/mDNS/Open services, and produce machine-readable summaries (CSV).  
**Important:** these tools perform network scanning. Use **only** on networks and devices you own or have explicit permission to test.

---

## Contents

- `reduced_noise_identify.sh` — conservative scan of common informative ports (Linux/macOS).
- `aggressive_identify.sh` — per-host full-port scan variant for a single host (previously provided).
- `batch_identify_to_csv.sh` — batch scanner that scans common ports and writes `summary.csv` (CSV).
- `batch_identify_fullport_to_csv.sh` — **FULL-PORT** variant (all TCP ports) — **very noisy** and slow.
- `win_batch_identify.ps1` — PowerShell batch scanner for Windows (common ports).
- `win_batch_identify_fullport.ps1` — PowerShell **full-port** scanner (Windows Administrator mode).
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

### E) Windows PowerShell (Admin) — full-port scan

Open PowerShell as Administrator:

```powershell
.\win_batch_identify_fullport.ps1 -InputFile .\ips.txt
```

Output folder: `batch_fullport_scan_YYYYMMDD_HHMMSS\`
Contains:

* `discovered.txt` — discovered live hosts
* `summary.csv` — combined summary
* `scan_<ip>.nmap/.gnmap/.xml` — per-host details

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

---

## Example: Windows full-port run

```powershell
PS> .\win_batch_identify_fullport.ps1 -InputFile .\ips.txt
```

**Output folder contents:**

```
batch_fullport_scan_20251031_120500\
 ├── discovered.txt
 ├── summary.csv
 ├── scan_192.168.1.80.nmap
 ├── scan_192.168.1.104.nmap
 └── ...
```

**Tip:** open `summary.csv` in Excel or Power BI for quick filtering — look for:

* Vendor = *Raspberry Pi Trading*
* Hostnames like *pi.hole* or *raspberrypi.local*
* SSH or HTTP ports open on Linux banners

---

## FAQs

**Q: Will this find devices behind another subnet or NAT?**
A: No — MAC OUI and ARP are limited to the local layer-2 network. For devices behind routers/NAT, you can only see their external addresses and open ports.

**Q: Can these scripts discover devices using IPv6?**
A: Not directly — they are written for IPv4. You can adapt to IPv6; nmap supports IPv6 scanning but discovery and MAC capture differ.

**Q: Can I change output to include timestamped logs?**
A: Yes — modify the script to append timestamps to CSV lines (e.g., add `$(date -Iseconds)` or `(Get-Date)` when writing rows).

---

## Contact / next steps

If you want, I can:

* produce a **CSV → JSON converter** (robust with embedded commas/quotes),
* add an **OS fingerprint summary analyzer** (Python script),
* or generate an **HTML dashboard** from your CSV outputs for quick filtering and search.

