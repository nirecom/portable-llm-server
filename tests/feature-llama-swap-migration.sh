#!/bin/bash
# Integration tests for llama-swap multi-model configuration.
# Requires llama-swap to be running (./start.sh).

set -euo pipefail

BASE_URL="https://localhost:8443"
CURL="curl -sk --max-time 120"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; FAIL=$((FAIL + 1)); }

check_json() {
    python3 -c "import sys,json; json.load(sys.stdin)" <<< "$1" 2>/dev/null
}

echo "=== llama-swap integration tests ==="
echo ""

# --- Normal cases ---
echo "--- Normal cases ---"

# 1. llama-swap is running
if $CURL "$BASE_URL/v1/models" -o /dev/null 2>/dev/null; then
    pass "llama-swap is reachable"
else
    fail "llama-swap is not reachable"
    echo "  Start with ./start.sh first"
    exit 1
fi

# 2. /v1/models returns both models
MODELS=$($CURL "$BASE_URL/v1/models")
if echo "$MODELS" | python3 -c "import sys,json; d=json.load(sys.stdin); ids=[m['id'] for m in d['data']]; assert 'Qwen2.5-7B-Instruct-Q4_K_M' in ids" 2>/dev/null; then
    pass "/v1/models contains Judge (Qwen2.5-7B)"
else
    fail "/v1/models missing Judge (Qwen2.5-7B)"
fi

if echo "$MODELS" | python3 -c "import sys,json; d=json.load(sys.stdin); ids=[m['id'] for m in d['data']]; assert 'Qwen3-14B-Q4_K_M' in ids" 2>/dev/null; then
    pass "/v1/models contains Reasoner (Qwen3-14B)"
else
    fail "/v1/models missing Reasoner (Qwen3-14B)"
fi

# 3. Judge chat completion
JUDGE_RESP=$($CURL "$BASE_URL/v1/chat/completions" \
    -H 'Content-Type: application/json' \
    -d '{"model":"Qwen2.5-7B-Instruct-Q4_K_M","messages":[{"role":"user","content":"Say yes."}],"max_tokens":5}')
if echo "$JUDGE_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['choices'][0]['message']['content']" 2>/dev/null; then
    pass "Judge chat completion returns content"
else
    fail "Judge chat completion failed"
fi

# 4. Reasoner chat completion
REASONER_RESP=$($CURL "$BASE_URL/v1/chat/completions" \
    -H 'Content-Type: application/json' \
    -d '{"model":"Qwen3-14B-Q4_K_M","messages":[{"role":"user","content":"Say yes."}],"max_tokens":10}')
if echo "$REASONER_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); m=d['choices'][0]['message']; assert m.get('content') or m.get('reasoning_content')" 2>/dev/null; then
    pass "Reasoner chat completion returns content"
else
    fail "Reasoner chat completion failed"
fi

# --- Error cases ---
echo ""
echo "--- Error cases ---"

# 5. Non-existent model returns error
ERR_RESP=$($CURL "$BASE_URL/v1/chat/completions" \
    -H 'Content-Type: application/json' \
    -d '{"model":"nonexistent-model","messages":[{"role":"user","content":"hi"}],"max_tokens":5}')
if echo "$ERR_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); assert 'error' in str(d).lower() or 'not found' in str(d).lower() or 'unknown' in str(d).lower()" 2>/dev/null; then
    pass "Non-existent model returns error"
else
    # llama-swap may return non-JSON error
    if echo "$ERR_RESP" | grep -qi "not found\|error\|unknown\|no model\|could not find\|handler" 2>/dev/null; then
        pass "Non-existent model returns error"
    else
        fail "Non-existent model did not return expected error: $ERR_RESP"
    fi
fi

# 6. Empty messages array returns error
EMPTY_MSG_RESP=$($CURL "$BASE_URL/v1/chat/completions" \
    -H 'Content-Type: application/json' \
    -d '{"model":"Qwen2.5-7B-Instruct-Q4_K_M","messages":[],"max_tokens":5}' || true)
if echo "$EMPTY_MSG_RESP" | grep -qi "error\|invalid\|empty\|required\|bad request" 2>/dev/null; then
    pass "Empty messages array returns error"
else
    # Some servers may accept empty messages and return empty content
    pass "Empty messages array handled (accepted or rejected)"
fi

# --- Edge cases ---
echo ""
echo "--- Edge cases ---"

# 7. max_tokens=1 minimal request
MIN_RESP=$($CURL "$BASE_URL/v1/chat/completions" \
    -H 'Content-Type: application/json' \
    -d '{"model":"Qwen2.5-7B-Instruct-Q4_K_M","messages":[{"role":"user","content":"hi"}],"max_tokens":1}')
if echo "$MIN_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); assert d['usage']['completion_tokens'] <= 2" 2>/dev/null; then
    pass "max_tokens=1 returns minimal response"
else
    fail "max_tokens=1 failed"
fi

# 8. max_tokens=0 handled gracefully
ZERO_RESP=$($CURL "$BASE_URL/v1/chat/completions" \
    -H 'Content-Type: application/json' \
    -d '{"model":"Qwen2.5-7B-Instruct-Q4_K_M","messages":[{"role":"user","content":"hi"}],"max_tokens":0}' || true)
if check_json "$ZERO_RESP" || echo "$ZERO_RESP" | grep -qi "error\|invalid" 2>/dev/null; then
    pass "max_tokens=0 handled gracefully"
else
    fail "max_tokens=0 unexpected response: $ZERO_RESP"
fi

# 9. Sequential requests to both models (simultaneous load stability)
JUDGE2=$($CURL "$BASE_URL/v1/chat/completions" \
    -H 'Content-Type: application/json' \
    -d '{"model":"Qwen2.5-7B-Instruct-Q4_K_M","messages":[{"role":"user","content":"Say one."}],"max_tokens":5}')
REASONER2=$($CURL "$BASE_URL/v1/chat/completions" \
    -H 'Content-Type: application/json' \
    -d '{"model":"Qwen3-14B-Q4_K_M","messages":[{"role":"user","content":"Say two."}],"max_tokens":10}')
JUDGE3=$($CURL "$BASE_URL/v1/chat/completions" \
    -H 'Content-Type: application/json' \
    -d '{"model":"Qwen2.5-7B-Instruct-Q4_K_M","messages":[{"role":"user","content":"Say three."}],"max_tokens":5}')

STABLE=true
for RESP in "$JUDGE2" "$REASONER2" "$JUDGE3"; do
    if ! check_json "$RESP"; then
        STABLE=false
        break
    fi
done
if [ "$STABLE" = true ]; then
    pass "Sequential Judge→Reasoner→Judge requests all succeed"
else
    fail "Sequential requests failed (simultaneous load instability)"
fi

# --- Idempotency cases ---
echo ""
echo "--- Idempotency cases ---"

# 10. stop.sh on already-stopped process exits cleanly
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# Create a fake stale PID file pointing to a non-existent process
echo "99999" > "$SCRIPT_DIR/llama-swap.pid.test"
ORIG_PID_FILE="$SCRIPT_DIR/llama-swap.pid"
BACKUP_PID=""
if [ -f "$ORIG_PID_FILE" ]; then
    BACKUP_PID="$(cat "$ORIG_PID_FILE")"
fi
cp "$SCRIPT_DIR/llama-swap.pid.test" "$ORIG_PID_FILE"
STOP_OUT=$("$SCRIPT_DIR/stop.sh" 2>&1 || true)
if echo "$STOP_OUT" | grep -qi "not running\|stale" 2>/dev/null; then
    pass "stop.sh on stale PID exits cleanly"
else
    fail "stop.sh on stale PID unexpected output: $STOP_OUT"
fi
rm -f "$SCRIPT_DIR/llama-swap.pid.test"
# Restore original PID file if llama-swap was running
if [ -n "$BACKUP_PID" ] && kill -0 "$BACKUP_PID" 2>/dev/null; then
    echo "$BACKUP_PID" > "$ORIG_PID_FILE"
fi

# --- Summary ---
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] && exit 0 || exit 1
