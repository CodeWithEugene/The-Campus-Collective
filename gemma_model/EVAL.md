# Eval run — exact steps (molab RTX Pro 6000)

The eval set (`data/eval.jsonl`) is generated deterministically (seed 3407) and
committed, so this is two commands on molab. GPU needed only because the models
load 4-bit via Unsloth.

```bash
cd gemma_model
pip install -r requirements.txt

# 1) Base model
python scripts/5_eval.py --model unsloth/gemma-4-E4B-it --tag base

# 2) Fine-tuned (merged, on HF)
python scripts/5_eval.py --model Eugeniuss/gemma-4-tcc-e4b --tag tuned
```

Output: `out/results.md` — the before/after table (tool_call_valid_json,
extraction_field_acc, lang_match). Paste it into:

1. `submission/writeup.md` §6 (replace the placeholder table)
2. The Kaggle writeup itself

Then add the two on-device numbers by hand (tokens/sec on the flagship demo
phone and the budget phone — read them from the app's chat streaming speed).

If `data/eval.jsonl` is missing on the molab checkout, regenerate identically:
`python scripts/1_generate_data.py` (no GPU needed, ~2 min).
