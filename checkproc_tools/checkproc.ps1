<#
checkproc.ps1 — verify details of a running process by PID
Usage: .\checkproc.ps1 -Pid 2134
Optional: set $env:VT_API_KEY = "your_api_key" for VirusTotal lookup
#>

param(
    [Parameter(Mandatory = $true)]
    [int]$Pid
)

try {
    $proc = Get-Process -Id $Pid -ErrorAction Stop
} catch {
    Write-Host "❌ PID $Pid not found."
    exit 1
}

Write-Host "🔍 Checking process PID $Pid"
Write-Host "------------------------------------------------------"
$proc | Format-List Id,ProcessName,StartTime,Path,Company

$path = $proc.Path
if (-not $path) {
    Write-Host "⚠️ No executable path found (possible system process)."
    exit 0
}

Write-Host ""
Write-Host "📁 File Details:"
Get-Item $path | Format-List Name,Directory,Length,LastWriteTime,Attributes

Write-Host ""
Write-Host "🔑 SHA256 Hash:"
$hash = Get-FileHash -Path $path -Algorithm SHA256
$hash | Format-List

if ($env:VT_API_KEY) {
    Write-Host ""
    Write-Host "🌐 VirusTotal lookup for $($hash.Hash)..."
    $headers = @{ "x-apikey" = $env:VT_API_KEY }
    try {
        $resp = Invoke-RestMethod -Uri "https://www.virustotal.com/api/v3/files/$($hash.Hash)" -Headers $headers -ErrorAction Stop
        $resp.data.attributes.last_analysis_stats | Format-List
    } catch {
        Write-Host "⚠️ Unable to query VirusTotal: $_"
    }
} else {
    Write-Host ""
    Write-Host "💡 Set $env:VT_API_KEY to enable VirusTotal lookups."
}

Write-Host "------------------------------------------------------"
Write-Host "✅ Done."
