# TCC Gemma Fine-Tuning Pipeline

Fine-tune **Gemma 4 E4B** into **`campus-collective/gemma-4-tcc`**, a trilingual
(English / Kiswahili / Sheng) on-device campus assistant, then ship it to the phone
via Hugging Face. Built to run on the **RTX Pro 6000 (96 GB)** on molab.marimo.io.

> Grounded against the real 2026 model landscape (verified on Hugging Face July 2026):
> `google/gemma-4-E4B-it`, `unsloth/gemma-4-E4B-it`, `litert-community/gemma-4-E4B-it-litert-lm`
> and the QAT-mobile variants all exist and have day-one Unsloth + LiteRT support.

---

## 1. Which model, and why

| Question | Decision | Reason |
|---|---|---|
| Base to fine-tune | **`google/gemma-4-E4B-it`** (Unsloth mirror `unsloth/gemma-4-E4B-it`) | Must run on a 6–8 GB phone → edge tier only (E2B/E4B). Of those, **E4B has clearly better Swahili/Sheng quality**, and QLoRA on it fits the 96 GB GPU with huge headroom. |
| Deploy on device | **E4B on 8 GB+ phones, E2B on 6 GB** | Same adapter recipe; the Supabase `model_manifest` (app §17) picks the variant per device. E2B is also the guaranteed-working fallback (stock `.litertlm` already runs in the app today). |
| Teacher for data | **`google/gemma-4-26B-A4B-it`** or **`gemma-4-31B-it`** (fits 96 GB) | Distill high-quality trilingual + reasoning data we can't get from public sets. |
| NOT chosen | 12B / 26B / 31B as the *shipped* model | Can't run on the target hardware. Teacher-only. |

## 2. What the fine-tune teaches (three skills)
1. **Trilingual instruction-following** — EN↔SW↔Sheng code-switch in real Kenyan-student register; concise, practical answers.
2. **Structured document extraction** — fee statement / HELB letter / timetable / receipt → strict JSON matching the app's `ScanResult` schema.
3. **Tool-calling** — emit the app's function calls (`mpesa_tariff`, `ledger_add`, `budget_make`, `matatu_fare`, `task_add`, `plan_day`, `set_reminder`, `safety_contacts`) with correct flat-JSON args.

## 3. Where the data comes from (three sources, mixed)
1. **Programmatic templates (highest reliability)** — tool-calling and doc-extraction pairs are generated deterministically from the app's real tool schemas + content packs (`data/content/*.json`). Known-correct outputs, no model needed. → `scripts/1_generate_data.py`
2. **Teacher distillation** — Gemma 4 26B/31B on the GPU generates natural trilingual chat / explanation pairs from campus scenario seeds. → same script, `--distill`
3. **Public Swahili SFT data** — mix in a Swahili slice of `CohereForAI/aya_collection` and `lelapa/Inkuba-instruct` to strengthen general Swahili instruction-following. Plus the hand-collected **Kiembu phrasebook** (`data/kiembu_phrasebook.jsonl`) — the honest local moat.

## 4. The pipeline (run in order on molab)
```
scripts/1_generate_data.py   →  data/train.jsonl, data/eval.jsonl   (build the dataset)
scripts/2_train_qlora.py     →  out/adapter/                        (Unsloth QLoRA on E4B)
scripts/3_merge_and_push.py  →  out/merged/ + HF repo               (merge LoRA, push to HF)
scripts/4_convert_ondevice.py→  out/gemma-4-tcc-e4b.litertlm/.task  (on-device format)  ⚠ risky step
scripts/5_eval.py            →  out/results.md                      (before/after eval table)
```
See `notebooks/marimo_train.py` for the same flow as a marimo notebook (molab-native).

## 5. ⚠️ The one genuinely hard step — on-device conversion
Fine-tuning is easy and well-supported. **Getting the result into `.litertlm`/`.task` is the risk.**
Verified facts (July 2026):
- Loading a **separate LoRA adapter** on a `.litertlm` model is **not yet a public API**
  (open feature request `google-ai-edge/LiteRT-LM#1188`). So don't rely on Path A.
- The **documented, working path** is: **merge LoRA into the base → convert with
  `ai-edge-torch` → package as `.task` (MediaPipe) or `.litertlm`**. flutter_gemma loads both.
- This conversion for a 4B multimodal model can require iteration; budget real time for it.

**De-risking plan (do this):**
- The app **already ships and demos on the stock `litert-community/gemma-4-E2B-it-litert-lm`**
  (no conversion needed). So the fine-tune is an *upgrade*, never a blocker.
- Try conversion on the smaller **E2B** first (faster iteration) before E4B.
- If conversion isn't ready by the deadline: ship stock on-device + prove the fine-tune's
  value with the **eval table** (§5 script) and, optionally, a hosted demo of the tuned model.
  The Technical-Depth score comes from the eval + real engineering, not from the format.

## 6. Setup
```bash
cd gemma_model
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env      # paste your HF read+write token into .env
huggingface-cli login     # or rely on HF_TOKEN from .env
```
Set your HF org/repo in `config.yaml` (`hub.repo_id`). Then run the scripts in order.

## 7. Output artifacts (what ends up on Hugging Face)
- `campus-collective/gemma-4-tcc-e4b` — merged fine-tuned model (Apache-2.0, **ungated** →
  the app can download it with no HF login, which also fixes first-run friction).
- `campus-collective/gemma-4-tcc-e4b-lora` — the LoRA adapter alone (small, for reproducibility).
- `campus-collective/gemma-4-tcc-e4b-litertlm` — the on-device `.litertlm`/`.task` (once converted).
- The app points `model_manifest.url` (Supabase §17) at the on-device repo — swap in with no app update.

## 8. Honesty notes (put these in the Kaggle writeup)
- Kiembu is a small hand-collected phrasebook, not a trained language — say so.
- Sheng is prompt/rare-example level, not full fluency.
- Report exact eval deltas (base vs tuned), not vibes.
