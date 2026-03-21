# Portable LLM Server

HTTPS-enabled llama-swap for portable devices (MacBook, notebook PCs).
Manages multiple models (Judge + Reasoner) with automatic hot-swapping.

## Prerequisites

### macOS

```bash
brew install llama.cpp mkcert
brew install mostlygeek/llama-swap/llama-swap
```

### Windows

```powershell
# llama.cpp: download pre-built binary from https://github.com/ggml-org/llama.cpp/releases
# llama-swap: download from https://github.com/mostlygeek/llama-swap/releases
# mkcert: download from https://github.com/FiloSottile/mkcert/releases
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

### 3. Download models via LM Studio

- **Judge**: `lmstudio-community/Qwen2.5-7B-Instruct-GGUF` (Q4_K_M)
- **Reasoner**: `bartowski/Qwen3.5-27B-Q4_K_M-GGUF` (Q4_K_M)

### 4. Configure

```bash
cp .env.example .env
vi .env  # Set HOST and PORT if needed
```

Model paths are configured in `config.yaml`. Update paths to match your LM Studio model locations.

### 5. Start / Stop

```bash
./start.sh       # start in background
./stop.sh        # stop
```

Logs are written to `llama-swap.log` in the project directory.

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

## Models

| Role | Model | Group | Behavior |
|------|-------|-------|----------|
| Judge | Qwen2.5-7B-Instruct-Q4_K_M | forever | Always loaded (CPU) |
| Reasoner | Qwen3.5-27B-Q4_K_M | heavy | Loaded on demand, swapped out after TTL |

## Files

| File | Git | Description |
|------|-----|-------------|
| `.env.example` | yes | Template with placeholders |
| `.env` | no | Actual config (secrets) |
| `config.yaml` | yes | llama-swap model configuration |
| `certs/` | no | TLS certificates (machine-specific) |
| `start.sh` | yes | Start llama-swap in background |
| `stop.sh` | yes | Stop llama-swap |
| `setup-certs.sh` | yes | Certificate generation helper |
| `*.pid` | no | Runtime PID file |
| `*.log` | no | Runtime log file |
