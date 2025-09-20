#!/bin/bash

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

# Flags
all=false
verbose=false
usb=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --all) all=true ;;
        --verbose) verbose=true ;;
        --usb) usb=true ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

timestamp=$(TZ="Europe/London" date +"%d-%m-%Y, %H:%M:%S%:z")

bt_devices=()
usb_devices=()

##############################################
# Collect Bluetooth devices (hcitool + GATT) #
##############################################
mapfile -t paired < <(bluetoothctl paired-devices | awk '{print $2,$3,$4,$5,$6,$7,$8}')
for line in "${paired[@]}"; do
    mac=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | cut -d' ' -f2-)
    battery=""

    # Read battery info via bluetoothctl
    info=$(timeout 5 bluetoothctl info "$mac" 2>/dev/null)
    if echo "$info" | grep -qi "Battery"; then
        battery=$(echo "$info" | grep "Battery" | awk '{print $2}')
    fi

    if [[ -n "$battery" || "$verbose" == true ]]; then
        bt_devices+=("$name,$mac,$battery")
    fi
done

##############################################
# Collect USB devices (via sysfs)            #
##############################################
if [[ "$usb" == true ]]; then
    for dev in /sys/class/power_supply/*; do
        if [[ -f "$dev/status" && -f "$dev/capacity" ]]; then
            id=$(basename "$dev")
            status=$(<"$dev/status")
            capacity=$(<"$dev/capacity")
            usb_devices+=("$id,$status,${capacity}%")
        fi
    done
fi

##############################################
# JSON Output (NDJSON format)                #
##############################################
devices_json=""

# Bluetooth
for bt in "${bt_devices[@]}"; do
    name=$(echo "$bt" | cut -d',' -f1)
    mac=$(echo "$bt" | cut -d',' -f2)
    battery=$(echo "$bt" | cut -d',' -f3)
    devices_json+="{\"name\":\"$name\",\"mac\":\"$mac\",\"battery\":\"$battery\",\"type\":\"bluetooth\"},"
done

# USB
for usb in "${usb_devices[@]}"; do
    id=$(echo "$usb" | cut -d',' -f1)
    status=$(echo "$usb" | cut -d',' -f2)
    battery=$(echo "$usb" | cut -d',' -f3)
    devices_json+="{\"name\":\"$id\",\"battery\":\"$battery\",\"status\":\"$status\",\"type\":\"usb\"},"
done

# Trim trailing comma
devices_json="[${devices_json%,}]"

json_output="{\"timestamp\":\"$timestamp\",\"devices\":$devices_json}"

# Append to JSON log
echo "$json_output" >> "$LOG_FILE_JSON"

##############################################
# CSV Output                                 #
##############################################
for bt in "${bt_devices[@]}"; do
    name=$(echo "$bt" | cut -d',' -f1)
    mac=$(echo "$bt" | cut -d',' -f2)
    battery=$(echo "$bt" | cut -d',' -f3)
    echo "$timestamp,$name,$mac,$battery,bluetooth" >> "$LOG_FILE_CSV"
done

for usb in "${usb_devices[@]}"; do
    id=$(echo "$usb" | cut -d',' -f1)
    status=$(echo "$usb" | cut -d',' -f2)
    battery=$(echo "$usb" | cut -d',' -f3)
    echo "$timestamp,$id,,$battery,$status,usb" >> "$LOG_FILE_CSV"
done

##############################################
# Pretty Console Output                      #
##############################################
printf "\n%-20s %-20s %-10s %-10s\n" "Name" "MAC/ID" "Battery" "Type"
printf "%-20s %-20s %-10s %-10s\n" "--------------------" "--------------------" "----------" "----------"

for bt in "${bt_devices[@]}"; do
    name=$(echo "$bt" | cut -d',' -f1)
    mac=$(echo "$bt" | cut -d',' -f2)
    battery=$(echo "$bt" | cut -d',' -f3)
    printf "%-20s %-20s %-10s %-10s\n" "$name" "$mac" "$battery" "bluetooth"
done

for usb in "${usb_devices[@]}"; do
    id=$(echo "$usb" | cut -d',' -f1)
    status=$(echo "$usb" | cut -d',' -f2)
    battery=$(echo "$usb" | cut -d',' -f3)
    printf "%-20s %-20s %-10s %-10s\n" "$id" "$status" "$battery" "usb"
done
