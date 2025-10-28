#!/usr/bin/env bash
# Web Service Audit Script – inspects Apache/Nginx bindings on ports 80 (HTTP) & 443 (HTTPS)
# Safe, read-only diagnostics for local security hardening

for PORT in 80 443; do
  echo "=== Checking if anything is listening on port $PORT ==="
  sudo ss -tulnp | grep -w ":$PORT" || echo "✅ No process currently listening on port $PORT"
  echo
done

echo "=== Listing web server processes (Apache, Nginx, Lighttpd, etc.) ==="
ps -eo pid,comm,cmd | egrep 'apache2|httpd|nginx|lighttpd' || echo "✅ No web server processes found"

echo
echo "=== Checking enabled Apache virtual hosts ==="
if command -v apache2ctl &>/dev/null; then
  sudo apache2ctl -S 2>/dev/null || echo "ℹ️ apache2ctl -S returned no virtual hosts"
elif command -v httpd &>/dev/null; then
  sudo httpd -S 2>/dev/null || echo "ℹ️ httpd -S returned no virtual hosts"
else
  echo "❌ Apache not installed."
fi

echo
echo "=== Listing Apache site configs (if present) ==="
sudo ls -1 /etc/apache2/sites-enabled/ 2>/dev/null || echo "ℹ️ No enabled site configs found"

echo
echo "=== Checking which processes have active connections to ports 80/443 ==="
sudo lsof -nP -i :80 -i :443 | awk 'NR==1 || /ESTABLISHED/' || echo "✅ No active HTTP/HTTPS connections found"

echo
echo "=== Searching for services using local HTTP/HTTPS endpoints ==="
sudo netstat -plant 2>/dev/null | egrep '(:80|:443)' || echo "✅ No local services found using HTTP/HTTPS"

echo
echo "=== Summary ==="
echo "If all checks show ✅ or ℹ️, your system isn't hosting anything on ports 80 or 443."
echo "You can safely stop and mask Apache/Nginx with:"
echo "    sudo systemctl disable --now apache2 nginx"
echo "    sudo systemctl mask apache2 nginx"

