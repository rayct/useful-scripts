<#
.SYNOPSIS
  Full-port batch scanner -> CSV summary (Windows PowerShell)
.DESCRIPTION
  Discovers live hosts from a list of IPs/CIDRs and runs a full TCP port scan
  (-p-) with version and OS detection.  Writes combined summary.csv and per-host
  nmap output files.  Very noisy and slow — use only on networks you own or have
  explicit permission to test.
.EXAMPLE
  PS> .\win_batch_identify_fullport.ps1 -InputFile .\ips.txt -OutDir .\scanout
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [string]$OutDir = ("batch_fullport_scan_" + (Get-Date -Format "yyyyMMdd_HHmmss")),

    [string]$NmapFlags = "-sS -p- -T4 -sV --version-all -O --osscan-guess --reason --script=banner,mdns-discovery"
)

if (-not (Test-Path $InputFile)) {
    Write-Host "File $InputFile not found." -ForegroundColor Red
    exit 2
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$discoverFile = Join-Path $OutDir "discovered.txt"
$csvFile = Join-Path $OutDir "summary.csv"

Write-Host "Starting full-port batch scan"
Write-Host "Output directory: $OutDir"
Write-Host ""

# 0) Discover live hosts
Write-Host "Discovering live hosts..."
$allIps = @()
Get-Content $InputFile | ForEach-Object {
    $line = $_.Split('#')[0].Trim()
    if ($line) {
        Write-Host "  -> $line"
        $result = nmap.exe -sn $line
        $ips = ($result | Select-String -Pattern 'Nmap scan report for (\d+\.\d+\.\d+\.\d+)' | ForEach-Object {
            ($_ -match 'Nmap scan report for (\d+\.\d+\.\d+\.\d+)') | Out-Null; $matches[1]
        })
        $allIps += $ips
    }
}
$allIps = $allIps | Sort-Object -Unique
if (-not $allIps) {
    Write-Host "No live hosts found. Exiting."
    exit 0
}
$allIps | Out-File $discoverFile -Encoding ASCII
Write-Host "Live hosts:`n$($allIps -join "`n")"
Write-Host ""

# 1) Prepare CSV header
"ip,hostname,mac,vendor,open_ports,services,os,nmap_base,scan_flags" | Out-File $csvFile -Encoding UTF8

# 2) Scan each host
foreach ($ip in $allIps) {
    Write-Host "Scanning $ip ..."
    $safe = $ip -replace '[^0-9A-Za-z_\.]', '_'
    $base = Join-Path $OutDir ("scan_" + $safe)
    & nmap.exe $NmapFlags -oA $base $ip | Out-Null

    $nmapfile = "$base.nmap"
    if (-not (Test-Path $nmapfile)) { continue }

    $lines = Get-Content $nmapfile
    $hostname = ""
    $mac = ""
    $vendor = ""
    $open_ports = ""
    $services = ""
    $os = ""

    $hostline = $lines | Where-Object { $_ -match '^Nmap scan report for' } | Select-Object -First 1
    if ($hostline -match 'Nmap scan report for ([^ ]+) \(') {
        $hostname = $matches[1]
    }

    $macline = $lines | Where-Object { $_ -match 'MAC Address:' } | Select-Object -First 1
    if ($macline) {
        if ($macline -match 'MAC Address: ([0-9A-F:]+) \((.+)\)') {
            $mac = $matches[1]; $vendor = $matches[2]
        }
    }

    $portLines = $false
    foreach ($line in $lines) {
        if ($line -match '^PORT') { $portLines = $true; continue }
        if ($line -match '^Host script results:' -or $line -match '^Service detection performed') { $portLines = $false }
        if ($portLines -and $line.Trim()) {
            $parts = $line -split '\s+'
            if ($parts.Length -ge 3) {
                $port = $parts[0]; $service = $parts[2]
                $version = ($parts[3..($parts.Length-1)] -join ' ') -replace ',', ';'
                $open_ports += "$port;"
                $services += "$port:$service/$version;"
            }
        }
    }

    $osLine = ($lines | Where-Object { $_ -match '^OS details:' } | Select-Object -First 1)
    if (-not $osLine) { $osLine = ($lines | Where-Object { $_ -match '^OS guesses:' } | Select-Object -First 1) }
    if ($osLine) { $os = ($osLine -replace '^OS details:\s*','' -replace '^OS guesses:\s*','') }

    # CSV escape helper
    function CsvEscape($s) {
        '"' + ($s -replace '"','""') + '"'
    }

    ($ip,$hostname,$mac,$vendor,$open_ports,$services,$os,$base,$NmapFlags) |
        ForEach-Object { CsvEscape $_ } |
        ForEach-Object -Begin { $row = "" } -Process { $row += "$_," } -End {
            $row = $row.TrimEnd(',')
            Add-Content -Path $csvFile -Value $row
        }

    Write-Host "  -> $base.* complete"
}
Write-Host ""
Write-Host "Full-port scan complete."
Write-Host "CSV summary: $csvFile"
Write-Host "Per-host results: $OutDir\scan_*"
Write-Host ""
Write-Host "Note: This is a full-port (-p-) SYN scan with version & OS detection. Expect long runtimes and heavy network traffic."
exit 0


