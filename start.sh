#!/bin/bash
# Start llama-swap with HTTPS.
# Usage: ./start.sh

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check llama-swap is installed
if ! command -v llama-swap &>/dev/null; then
    echo "Error: llama-swap not found." >&2
    case "$(uname -s)" in
        Darwin) echo "Install with: brew install mostlygeek/llama-swap/llama-swap" >&2 ;;
        *) echo "Download from: https://github.com/mostlygeek/llama-swap/releases" >&2 ;;
    esac
    exit 1
fi

# Check llama-server is installed (used by llama-swap to run models)
if ! command -v llama-server &>/dev/null; then
    echo "Error: llama-server not found." >&2
    case "$(uname -s)" in
        Darwin) echo "Install with: brew install llama.cpp" >&2 ;;
        *) echo "Download from: https://github.com/ggml-org/llama.cpp/releases" >&2 ;;
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

if [ ! -f "$SSL_CERT_FILE" ]; then
    echo "Error: SSL cert not found: $SSL_CERT_FILE" >&2
    echo "Run: ./setup-certs.sh" >&2
    exit 1
fi

CONFIG_FILE="$PROJECT_DIR/config.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config.yaml not found." >&2
    exit 1
fi

PID_FILE="$PROJECT_DIR/llama-swap.pid"
LOG_FILE="$PROJECT_DIR/llama-swap.log"

# Check if already running
if [ -f "$PID_FILE" ]; then
    OLD_PID="$(cat "$PID_FILE")"
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Error: llama-swap is already running (PID $OLD_PID)" >&2
        echo "Run ./stop.sh first." >&2
        exit 1
    fi
    rm -f "$PID_FILE"
fi

echo "Starting llama-swap..."
echo "  Config: $CONFIG_FILE"
echo "  Listen: https://${HOST}:${PORT}"
echo "  Log:    $LOG_FILE"

nohup llama-swap \
    -config "$CONFIG_FILE" \
    -listen "${HOST}:${PORT}" \
    -tls-cert-file "$SSL_CERT_FILE" \
    -tls-key-file "$SSL_KEY_FILE" \
    -watch-config \
    > "$LOG_FILE" 2>&1 &

echo $! > "$PID_FILE"
echo "  PID:    $(cat "$PID_FILE")"
echo ""
echo "Started. Use ./stop.sh to stop."
