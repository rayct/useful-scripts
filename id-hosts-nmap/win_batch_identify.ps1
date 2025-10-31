<#
win_batch_identify.ps1
Usage (Admin PowerShell):
.\win_batch_identify.ps1 -InputFile .\ips.txt -OutDir .\out
ips.txt: one IP or CIDR per line.
Requires nmap.exe in PATH (or adjust $nmapPath).
#>

param(
  [Parameter(Mandatory=$true)][string]$InputFile,
  [string]$OutDir = ".\win_scan_$(Get-Date -Format yyyyMMdd_HHmmss)"
)

if (-not (Test-Path $InputFile)) {
  Write-Error "Input file not found: $InputFile"
  exit 2
}

$nmapPath = "nmap.exe"  # change if nmap not in PATH
New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$discovered = Join-Path $OutDir "discovered.txt"
Set-Content -Path $discovered -Value ""

# Discover live hosts
Get-Content $InputFile | ForEach-Object {
  $line = $_.Trim()
  if ($line -eq "") { return }
  Write-Output "Discovering: $line"
  $discover = & $nmapPath -sn $line
  $ips = $discover | Select-String -Pattern 'Nmap scan report for (\d+\.\d+\.\d+\.\d+)' | ForEach-Object {
      if ($_ -match 'Nmap scan report for (\d+\.\d+\.\d+\.\d+)') { $matches[1] }
  }
  $ips | ForEach-Object { Add-Content -Path $discovered -Value $_ }
}

$ipsUnique = Get-Content $discovered | Sort-Object -Unique
if (-not $ipsUnique) {
  Write-Output "No live hosts discovered."
  exit 0
}

$results = @()
# Common ports
$commonPorts = "22,23,53,67,68,80,443,139,445,1900,5353,8000,8080,8443"

foreach ($ip in $ipsUnique) {
  $safe = $ip -replace '\.','_'
  $base = Join-Path $OutDir "scan_$safe"
  Write-Output "Scanning $ip ..."
  & $nmapPath -sS -p $commonPorts -T4 -sV --version-light -O --osscan-guess --script=banner,mdns-discovery -oA $base $ip | Out-Null

  $nmapText = Get-Content "$base.nmap" -Raw -ErrorAction SilentlyContinue

  # Parse fields
  $hostLine = ($nmapText -split "`n" | Where-Object { $_ -like "Nmap scan report for *" } | Select-Object -First 1)
  $hostname = ""
  if ($hostLine) {
    if ($hostLine -match 'Nmap scan report for (.+) \(') { $hostname = $Matches[1].Trim() }
  }
  $macLine = ($nmapText -split "`n" | Where-Object { $_ -match "MAC Address:" } | Select-Object -First 1)
  $mac = ""
  $vendor = ""
  if ($macLine) {
    if ($macLine -match 'MAC Address:\s*([0-9A-Fa-f:]+)\s*\((.+)\)') { $mac = $Matches[1]; $vendor = $Matches[2] }
  }
  $openPorts = ($nmapText -split "`n" | Where-Object { $_ -match '^[0-9]+\/tcp' } | ForEach-Object { ($_ -split '\s+')[0] }) -join ';'
  $services = ($nmapText -split "`n" | Where-Object { $_ -match '^[0-9]+\/tcp' } | ForEach-Object {
      $parts = ($_ -split '\s+')
      $port = $parts[0]; $serv = $parts[2]; $version = if ($parts.Length -ge 4) { ($parts[3..($parts.Length-1)] -join ' ') } else { "" }
      return "$port:$serv/$version"
  }) -join ';'
  $os = ($nmapText -split "`n" | Where-Object { $_ -match 'OS details:' } | ForEach-Object { $_ -replace 'OS details:\s*','' }) | Select-Object -First 1

  $results += [PSCustomObject]@{
    ip = $ip
    hostname = $hostname
    mac = $mac
    vendor = $vendor
    open_ports = $openPorts
    services = $services
    os = $os
    nmap_base = $base
  }
}

$outCsv = Join-Path $OutDir "summary.csv"
$results | Export-Csv -Path $outCsv -NoTypeInformation -Encoding UTF8
Write-Output "Done. Summary: $outCsv"
Write-Output "Per-host nmap outputs in $OutDir"
exit 0