# Portable LLM Server

HTTPS-enabled llama-server for portable devices (MacBook, notebook PCs).

## Prerequisites

### macOS

```bash
brew install llama.cpp mkcert
```

### Windows

```powershell
# llama.cpp: download pre-built binary from https://github.com/ggml-org/llama.cpp/releases
# mkcert: download from https://github.com/FiloSottile/mkcert/releases
# Or via Chocolatey:
choco install mkcert
```

## Setup

### 1. Share mkcert CA from primary host (one-time)

Copy `rootCA.pem` and `rootCA-key.pem` from the primary mkcert CA host's CA directory into this machine's CA directory:

```bash
# Check CA directory
mkcert -CAROOT
# macOS → ~/Library/Application Support/mkcert/
# Linux → ~/.local/share/mkcert/

# Copy the primary CA files there, then install
mkcert -install
```

### 2. Generate TLS certificate

```bash
./setup-certs.sh
```

The script auto-detects the local IP address. To override: `./setup-certs.sh <your-ip>`

### 3. Download model via LM Studio

Search and download `Qwen2.5-7B-Instruct-GGUF` (Q4_K_M) from `lmstudio-community` in LM Studio.

### 4. Configure

```bash
cp .env.example .env
vi .env  # Set MODEL_PATH to the LM Studio model location
```

### 5. Start

```bash
./start.sh
```

## Verify

```bash
curl -s https://localhost:8443/health               # from this machine
curl -s https://<your-ip>:8443/health               # from other hosts
```

## Remote Access

Once running, the server is available at:

```
https://<your-ip>:8443/v1
```

Any OpenAI-compatible client can connect using this URL.

## Files

| File | Git | Description |
|------|-----|-------------|
| `.env.example` | ✅ | Template with placeholders |
| `.env` | ❌ | Actual config (secrets) |
| `certs/` | ❌ | TLS certificates (machine-specific) |
| `start.sh` | ✅ | Server startup |
| `setup-certs.sh` | ✅ | Certificate generation helper |
