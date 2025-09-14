#!/bin/bash
# bt-battery.sh
# Logs Bluetooth device battery levels in JSON and CSV

# Get directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Log directories
LOG_DIR_JSON="$SCRIPT_DIR/logs/json"
LOG_DIR_CSV="$SCRIPT_DIR/logs/csv"

# Ensure directories exist
mkdir -p "$LOG_DIR_JSON" "$LOG_DIR_CSV"

# Log file paths
LOG_FILE_JSON="$LOG_DIR_JSON/bt-battery-log.json"
LOG_FILE_CSV="$LOG_DIR_CSV/bt-battery-log.csv"

# Argument parsing
mode="Connected"
verbose=false

for arg in "$@"; do
    case $arg in
        --all) mode="Paired" ;;
        --verbose) verbose=true ;;
    esac
done

# Collect devices
devices=()
for dev in $(bluetoothctl devices $mode | awk '{print $2}'); do
    name=$(bluetoothctl info $dev | grep "Name:" | cut -d' ' -f2-)
    battery_raw=$(bluetoothctl info $dev | grep "Battery")

    if [[ -z "$battery_raw" ]]; then
        battery="No battery info"
    else
        if [[ "$battery_raw" =~ ([0-9]+)% ]]; then
            battery="${BASH_REMATCH[1]}%"
        elif [[ "$battery_raw" =~ \(([0-9]+)\) ]]; then
            battery="${BASH_REMATCH[1]}%"
        else
            battery="$battery_raw"
        fi
    fi

    if [[ "$battery" == "No battery info" && $verbose == false ]]; then
        continue
    fi

    devices+=("$name,$dev,$battery")
done

timestamp=$(date -u +"%d-%m-%YT%H:%M:%SZ")

# Output JSON log (always)
if [[ ${#devices[@]} -gt 0 ]]; then
    {
        echo -n "{\"timestamp\":\"$timestamp\",\"devices\":["
        for ((i=0; i<${#devices[@]}; i++)); do
            IFS=',' read -r name mac battery <<< "${devices[$i]}"
            if [[ $i -lt $(( ${#devices[@]} - 1 )) ]]; then
                echo -n "{\"name\":\"$name\",\"mac\":\"$mac\",\"battery\":\"$battery\"},"
            else
                echo -n "{\"name\":\"$name\",\"mac\":\"$mac\",\"battery\":\"$battery\"}"
            fi
        done
        echo "]}"
    } | tee -a "$LOG_FILE_JSON"
fi

# Output CSV log (always)
for dev in "${devices[@]}"; do
    echo "$timestamp,$dev" | tee -a "$LOG_FILE_CSV"
done

# Default pretty table for console
printf "%-25s %-20s %-10s\n" "Device Name" "MAC Address" "Battery"
printf "%-25s %-20s %-10s\n" "-----------" "-----------" "-------"
for dev in "${devices[@]}"; do
    IFS=',' read -r name mac battery <<< "$dev"
    printf "%-25s %-20s %-10s\n" "$name" "$mac" "$battery"
done
