#!/bin/bash
# Generate TLS certificates for llama-server using mkcert.
#
# Prerequisites:
#   brew install mkcert
#   Copy rootCA.pem and rootCA-key.pem from the primary mkcert CA host
#   into $(mkcert -CAROOT)/ then run: mkcert -install
#
# Usage: ./setup-certs.sh [IP_ADDRESS]
#   IP_ADDRESS: override auto-detected IP (optional)
#
# Examples:
#   ./setup-certs.sh
#   ./setup-certs.sh <your-ip>

set -euo pipefail

# Resolve project root
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CERTS_DIR="$PROJECT_DIR/certs"

mkdir -p "$CERTS_DIR"

CERT_FILE="$CERTS_DIR/llm-server.pem"
KEY_FILE="$CERTS_DIR/llm-server-key.pem"

# Check mkcert
if ! command -v mkcert &>/dev/null; then
    echo "Error: mkcert not found. Run: brew install mkcert" >&2
    exit 1
fi

# Check CA is installed
CAROOT="$(mkcert -CAROOT)"
if [ ! -f "$CAROOT/rootCA.pem" ]; then
    echo "Error: rootCA.pem not found in $CAROOT" >&2
    echo "Copy rootCA.pem and rootCA-key.pem from the primary CA host, then run: mkcert -install" >&2
    exit 1
fi

# Detect local IP address (via default route interface)
if [ -n "${1:-}" ]; then
    IP_ADDR="$1"
else
    IP_ADDR=""
    case "$(uname -s)" in
        Darwin)
            # macOS: get the interface used for default route, then its IP
            IFACE="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')"
            if [ -n "$IFACE" ]; then
                IP_ADDR="$(ipconfig getifaddr "$IFACE" 2>/dev/null || true)"
            fi
            ;;
        Linux)
            IP_ADDR="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' || true)"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            # Windows (Git Bash / MSYS2)
            IP_ADDR="$(powershell.exe -NoProfile -Command \
                "(Get-NetIPConfiguration | Where-Object { \$_.IPv4DefaultGateway } | Select-Object -First 1).IPv4Address.IPAddress" \
                2>/dev/null | tr -d '\r' || true)"
            ;;
    esac
    if [ -z "$IP_ADDR" ]; then
        echo "Error: Could not detect local IP. Specify manually: $0 <IP_ADDRESS>" >&2
        exit 1
    fi
fi

echo "Generating certificate for: $IP_ADDR"
echo "Output: $CERTS_DIR/"

mkcert -cert-file "$CERT_FILE" \
       -key-file  "$KEY_FILE" \
       "$IP_ADDR"

echo ""
echo "Certificate: $CERT_FILE"
echo "Key:         $KEY_FILE"
