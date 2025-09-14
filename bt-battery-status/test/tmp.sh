# JSON log (always)
if [[ ${#devices[@]} -gt 0 ]]; then
    {
        echo -n "{\"timestamp\":\"$timestamp\",\"devices\":["
        for ((i=0; i<${#devices[@]}; i++)); do
            IFS=',' read -r name mac battery <<< "${devices[$i]}"
            # Only add comma if not the last element
            if [[ $i -lt $(( ${#devices[@]} - 1 )) ]]; then
                echo -n "{\"name\":\"$name\",\"mac\":\"$mac\",\"battery\":\"$battery\"},"
            else
                echo -n "{\"name\":\"$name\",\"mac\":\"$mac\",\"battery\":\"$battery\"}"
            fi
        done
        echo "]}"   # Close JSON object
    } | tee -a "$LOG_FILE_JSON"
fi
