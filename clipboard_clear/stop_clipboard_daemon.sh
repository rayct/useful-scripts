# Robust stop for clipboard_clear_daemon
if [ -f clipboard_clear_daemon.pid ]; then
    PID=$(cat clipboard_clear_daemon.pid)
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        echo "Daemon stopped (PID $PID)."
    else
        echo "PID file found but process not running. Cleaning PID file."
    fi
    rm -f clipboard_clear_daemon.pid
else
    # Try to find any running instance by script name
    PID=$(pgrep -f auto_clear_clipboard_daemon.sh)
    if [ -n "$PID" ]; then
        kill $PID
        echo "Daemon stopped (PID $PID)."
    else
        echo "No running daemon found."
    fi
fi
