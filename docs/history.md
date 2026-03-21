# portable-llm-server history

### Reasoner model selection for Mac M4 Pro 24GB (aea5fad)

Background: llama-swap migration で Reasoner モデルを選定。当初 Qwen3.5-27B-Q4_K_M (unsloth) を予定していたが、M4 Pro 24GB のメモリ制約により断念し Qwen3-14B-Q4_K_M に変更。

**Qwen3.5-27B-Q4_K_M の問題:**
- モデルサイズ ~18.6GB で Judge 7B (~5GB) との同時ロード不可 (abort trap)
- 排他グループで交互ロードにしても推論速度 2.7〜3.4 tok/s と実用に耐えない
- スワップ時のオーバーヘッド +23秒

**Qwen3-14B-Q4_K_M ベンチマーク結果 (Judge 同時ロード):**

| シナリオ | 総レイテンシ | 推論速度 |
|----------|------------|---------|
| Judge コールドスタート | 7.4s | 51.4 tok/s |
| Judge ウォーム | 2.0s | 50.7 tok/s |
| Reasoner コールドスタート | 14.4s | 27.0 tok/s |
| Reasoner ウォーム | 3.8s | 27.1 tok/s |

**決定事項:**
- Mac: Reasoner は Qwen3-14B-Q4_K_M (Judge と同時ロード可)
- Win: Reasoner は Qwen3.5-27B-Q4_K_M (VRAM に余裕あり)
- Win/Mac で同一モデル統一の前提は破棄。ハードウェア制約に応じてモデルを分ける

**config.yaml 試行錯誤:**
- 複数行 cmd (`|-`) + `~` パスで llama-server 起動失敗 → 1行 + 絶対パスに修正
- `--flash-attn on` で 27B が abort trap → 削除しても解消せず (メモリが根本原因)
- 27B `--parallel 1` で起動成功するが速度が実用外
