# portable-llm-server todo

## Current Work

### llama-swap migration (In Progress)

- [x] Install llama-swap: `brew install mostlygeek/llama-swap/llama-swap`
- [x] Download Reasoner model via LM Studio
- [x] Update config.yaml model paths to match actual LM Studio locations
- [x] Update .env from new .env.example (remove MODEL_PATH etc.)
- [x] Test: `./start.sh` → verify both models load
- [x] Test: Judge endpoint responds
- [x] Test: Reasoner endpoint responds
- [ ] Verify LiteLLM proxy can reach both models via HTTPS
- [ ] ai-specs 側の docs にモデル変更を反映
