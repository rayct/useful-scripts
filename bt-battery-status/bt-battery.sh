#!/bin/bash

# Default: only connected devices
mode="Connected"
verbose=false

# Parse args
for arg in "$@"; do
    case $arg in
        --all) mode="Paired" ;;
        --verbose) verbose=true ;;
    esac
done

# Print header
printf "%-25s %-20s %-10s\n" "Device Name" "MAC Address" "Battery"
printf "%-25s %-20s %-10s\n" "-----------" "-----------" "-------"

for dev in $(bluetoothctl devices $mode | awk '{print $2}'); do
    name=$(bluetoothctl info $dev | grep "Name:" | cut -d' ' -f2-)
    battery_raw=$(bluetoothctl info $dev | grep "Battery")

    if [[ -z "$battery_raw" ]]; then
        battery="No battery info"
    else
        # Case 1: Already formatted like "Battery Percentage: 85%"
        if [[ "$battery_raw" =~ ([0-9]+)% ]]; then
            battery="${BASH_REMATCH[1]}%"
        # Case 2: Raw format like "0x32 (50)"
        elif [[ "$battery_raw" =~ \(([0-9]+)\) ]]; then
            battery="${BASH_REMATCH[1]}%"
        else
            battery="$battery_raw"
        fi
    fi

    # Skip devices with no battery info unless --verbose
    if [[ "$battery" == "No battery info" && $verbose == false ]]; then
        continue
    fi

    printf "%-25s %-20s %-10s\n" "$name" "$dev" "$battery"
done

