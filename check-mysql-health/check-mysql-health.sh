#!/bin/bash
# check-mysql-health.sh
# MySQL + systemd health check with CSV & JSON logging
# Author: rwxray

SERVICE="mysql"
LOG_DIR="./logs"
CSV_LOG="$LOG_DIR/mysql_health_log.csv"
JSON_LOG="$LOG_DIR/mysql_health_log.json"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# UK/GB timestamp: dd-mm-YYYY HH:MM:SS
TIMESTAMP=$(TZ="Europe/London" date +"%d-%m-%Y %H:%M:%S")

# Function to log results
log_result() {
    local step="$1"
    local status="$2"

    # CSV format
    echo "\"$TIMESTAMP\",\"$step\",\"$status\"" >> "$CSV_LOG"

    # JSON format (one object per line)
    echo "{\"timestamp\":\"$TIMESTAMP\",\"step\":\"$step\",\"status\":\"$status\"}" >> "$JSON_LOG"
}

# Function to check MySQL query access
check_mysql_query() {
    mysql -e "SELECT VERSION() AS Version, NOW() AS CurrentTime;" >/dev/null 2>&1
    return $?
}

echo "=== Checking systemd service status for $SERVICE ==="
systemctl is-active --quiet $SERVICE
if [ $? -eq 0 ]; then
    echo "[OK] $SERVICE is active and running."
    log_result "systemd_status" "OK"
else
    echo "[ERROR] $SERVICE is not running!"
    log_result "systemd_status" "ERROR"
    systemctl status $SERVICE --no-pager
    exit 1
fi

echo ""
echo "=== Checking MySQL server responsiveness ==="
mysqladmin ping >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "[OK] MySQL responded to ping."
    log_result "mysql_ping" "OK"
else
    echo "[ERROR] MySQL did not respond!"
    log_result "mysql_ping" "ERROR"
    exit 1
fi

echo ""
echo "=== Running a simple query ==="
if check_mysql_query; then
    RESULT=$(mysql -e "SELECT VERSION() AS Version, NOW() AS CurrentTime;")
    echo "[OK] Query executed successfully."
    echo "$RESULT"
    log_result "mysql_query" "OK"
else
    echo "[ERROR] Could not run test query. Check your MySQL credentials in ~/.my.cnf"
    log_result "mysql_query" "ERROR"
    exit 1
fi

echo ""
echo "✅ MySQL health check completed successfully."
log_result "script_complete" "OK"
