#!/bin/bash
# Stop llama-server.
# Usage: ./stop.sh

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$PROJECT_DIR/llama-server.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "llama-server is not running (no PID file)."
    exit 0
fi

PID="$(cat "$PID_FILE")"

if kill -0 "$PID" 2>/dev/null; then
    echo "Stopping llama-server (PID $PID)..."
    kill "$PID"
    # Wait up to 10 seconds for graceful shutdown
    for i in $(seq 1 10); do
        if ! kill -0 "$PID" 2>/dev/null; then
            break
        fi
        sleep 1
    done
    # Force kill if still running
    if kill -0 "$PID" 2>/dev/null; then
        echo "Force killing (PID $PID)..."
        kill -9 "$PID"
    fi
    echo "Stopped."
else
    echo "llama-server is not running (stale PID file)."
fi

rm -f "$PID_FILE"
