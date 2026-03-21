# portable-llm-server todo

## Current Work

### llama-swap migration (In Progress)

- [ ] Install llama-swap: `brew install mostlygeek/llama-swap/llama-swap`
- [ ] Download Qwen3.5-27B-Q4_K_M via LM Studio (bartowski)
- [ ] Update config.yaml model paths to match actual LM Studio locations
- [ ] Update .env from new .env.example (remove MODEL_PATH etc.)
- [ ] Test: `./start.sh` → verify both models load
- [ ] Test: Judge endpoint responds (forever group)
- [ ] Test: Reasoner endpoint responds (heavy group, on-demand load)
- [ ] Verify LiteLLM proxy can reach both models via HTTPS
