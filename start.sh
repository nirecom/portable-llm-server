#!/bin/bash
# Start llama-server with HTTPS.
# Usage: ./start.sh

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check llama-server is installed
if ! command -v llama-server &>/dev/null; then
    echo "Error: llama-server not found." >&2
    case "$(uname -s)" in
        Darwin|Linux) echo "Install with: brew install llama.cpp" >&2 ;;
        MINGW*|MSYS*|CYGWIN*) echo "Download from: https://github.com/ggml-org/llama.cpp/releases" >&2 ;;
    esac
    exit 1
fi

# Load .env
ENV_FILE="$PROJECT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env not found. Run 'cp .env.example .env' and fill in values." >&2
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

# Resolve paths relative to project directory
SSL_CERT_FILE="$PROJECT_DIR/${SSL_CERT_FILE#./}"
SSL_KEY_FILE="$PROJECT_DIR/${SSL_KEY_FILE#./}"
MODEL_PATH="${MODEL_PATH/#\~/$HOME}"

# Validate required values
if [ -z "${MODEL_PATH:-}" ]; then
    echo "Error: MODEL_PATH is not set in .env" >&2
    exit 1
fi

if [ ! -f "$MODEL_PATH" ]; then
    echo "Error: Model file not found: $MODEL_PATH" >&2
    exit 1
fi

if [ ! -f "$SSL_CERT_FILE" ]; then
    echo "Error: SSL cert not found: $SSL_CERT_FILE" >&2
    echo "Run: ./setup-certs.sh" >&2
    exit 1
fi

PID_FILE="$PROJECT_DIR/llama-server.pid"
LOG_FILE="$PROJECT_DIR/llama-server.log"

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID="$(cat "$PID_FILE")"
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Error: llama-server is already running (PID $OLD_PID)" >&2
        echo "Run ./stop.sh first." >&2
        exit 1
    fi
    rm -f "$PID_FILE"
fi

echo "Starting llama-server..."
echo "  Model:  $MODEL_PATH"
echo "  Listen: https://${HOST}:${PORT}"
echo "  Log:    $LOG_FILE"

nohup llama-server \
    -m "$MODEL_PATH" \
    --host "${HOST}" \
    --port "${PORT}" \
    --ssl-cert-file "$SSL_CERT_FILE" \
    --ssl-key-file "$SSL_KEY_FILE" \
    -ngl "${GPU_LAYERS:--1}" \
    > "$LOG_FILE" 2>&1 &

echo $! > "$PID_FILE"
echo "  PID:    $(cat "$PID_FILE")"
echo ""
echo "Started. Use ./stop.sh to stop."
