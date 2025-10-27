#!/usr/bin/env bash
# checkproc.sh — verify details of a running process by PID
# Works on Debian/Ubuntu, Fedora/RHEL, openSUSE, and macOS (limited)

set -euo pipefail

PID="${1:-}"
if [[ -z "$PID" ]]; then
  echo "Usage: $0 <pid>"
  exit 1
fi

if [[ ! -d "/proc/$PID" ]]; then
  echo "❌ PID $PID does not exist."
  exit 1
fi

EXE="$(readlink -f /proc/$PID/exe 2>/dev/null || true)"
if [[ -z "$EXE" ]]; then
  echo "❌ Could not resolve executable for PID $PID."
  exit 1
fi

echo "🔍 Checking process PID $PID"
echo "------------------------------------------------------"
ps -fp "$PID" || true
echo
echo "📁 Executable Path: $EXE"
echo "👤 Ownership and Permissions:"
ls -lh "$EXE"
echo

if command -v dpkg &>/dev/null; then
  echo "📦 Package Ownership (dpkg):"
  dpkg -S "$EXE" 2>/dev/null || echo "Not found in dpkg database."
elif command -v rpm &>/dev/null; then
  echo "📦 Package Ownership (rpm):"
  rpm -qf "$EXE" 2>/dev/null || echo "Not found in rpm database."
else
  echo "📦 Package manager not detected."
fi
echo

echo "🔑 SHA256 Hash:"
sha256sum "$EXE"
echo

if [[ -n "${VT_API_KEY:-}" ]]; then
  HASH=$(sha256sum "$EXE" | awk '{print $1}')
  echo "🌐 VirusTotal lookup for $HASH..."
  curl -s --request GET     --url "https://www.virustotal.com/api/v3/files/$HASH"     --header "x-apikey: $VT_API_KEY" | jq '.data.attributes.last_analysis_stats'
else
  echo "💡 Set VT_API_KEY to enable VirusTotal lookups."
fi

echo "------------------------------------------------------"
echo "✅ Done."
