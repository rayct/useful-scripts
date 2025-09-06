#!/bin/bash

# Log file location
LOG_FILE="/var/log/changed_files.log"

# Timestamp file to track last run
STAMP_FILE="/var/log/changed_files.stamp"

# Directories to search
SEARCH_PATH="/"

# Exclusions file (one path per line)
EXCLUDES_FILE="/etc/changed_files_excludes.txt"

# Build find exclude args from file
EXCLUDES=""
if [ -f "$EXCLUDES_FILE" ]; then
    while IFS= read -r path; do
        # Skip blank lines and comments
        [[ -z "$path" || "$path" =~ ^# ]] && continue
        EXCLUDES="$EXCLUDES -path $path -prune -o"
    done < "$EXCLUDES_FILE"
fi

# If stamp file doesn’t exist, initialize to 24h ago
if [ ! -f "$STAMP_FILE" ]; then
    date -d "24 hours ago" +%s > "$STAMP_FILE"
fi

LAST_RUN=$(cat "$STAMP_FILE")
CURRENT_TIME=$(date +%s)

# Capture changed files list
CHANGED_FILES=$(mktemp)
find $SEARCH_PATH $EXCLUDES -type f -newermt "@$LAST_RUN" -print > "$CHANGED_FILES"

# Count changed files
COUNT=$(wc -l < "$CHANGED_FILES")

# Write to log
{
    echo "========== $(date) =========="
    echo "Changed files since last run: $COUNT"
    
    if [ "$COUNT" -gt 0 ]; then
        echo "--- Top 10 biggest changed files ---"
        # Use du -h for human readable, sort by size, largest first
        du -h $(cat "$CHANGED_FILES") 2>/dev/null | sort -rh | head -n 10
        echo
        echo "--- Full list of changed files ---"
        cat "$CHANGED_FILES"
    else
        echo "No changes detected."
    fi
    echo
} >> "$LOG_FILE"

# Clean up
rm -f "$CHANGED_FILES"

# Update stamp
echo "$CURRENT_TIME" > "$STAMP_FILE"

