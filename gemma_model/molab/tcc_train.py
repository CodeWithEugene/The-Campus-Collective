"""TCC — self-contained Gemma 4 E4B fine-tune for molab (RTX Pro 6000).

Upload THIS ONE FILE to the root of your marimo workspace, then run the single
bootstrap cell (which sets HF_TOKEN, installs deps, and runs this script).

Does everything end to end:
  build dataset (programmatic tool-calls + doc-extraction + Kiembu + public Swahili)
  → QLoRA fine-tune gemma-4-E4B-it (Unsloth)
  → merge adapter → push merged model + LoRA to your Hugging Face account
  → quick eval → print the model URL.

On-device (.task/.litertlm) conversion is a SEPARATE step (different env) — see
gemma_model/scripts/4_convert_ondevice.py. This script produces the trained model on HF.

Env vars (the bootstrap cell sets these):
  HF_TOKEN   (required)  your HF read+write token
  HF_REPO    (optional)  target repo; default {your-username}/gemma-4-tcc-e4b
  MAX_STEPS  (optional)  set e.g. 30 for a quick smoke test; unset = full epochs
"""
import json, os, random, re

random.seed(3407)
HF_TOKEN = os.environ.get("HF_TOKEN")
assert HF_TOKEN, "Set HF_TOKEN env var first (see the bootstrap cell)."

# Pre-quantized 4-bit base: smaller/faster download, skips on-the-fly quantization.
BASE_ID = os.environ.get("BASE_ID", "unsloth/gemma-4-E4B-it-unsloth-bnb-4bit")
MAX_SEQ = 2048

# Xet download backend hangs at 0% in sandboxed envs (e.g. molab) — force classic HTTP.
os.environ.setdefault("HF_HUB_DISABLE_XET", "1")

SYSTEM = (
    "You are TCC, an offline campus assistant for University of Embu students. "
    "You reply in the user's language (English, Kiswahili or Sheng), stay concise "
    "and practical, and call tools when a task needs real computation or data."
)

# ---------------------------------------------------------------- data: tools
MPESA = [(101, 500, 7), (501, 1000, 13), (1001, 1500, 23), (1501, 2500, 33),
         (2501, 3500, 53), (3501, 5000, 57), (5001, 7500, 78), (7501, 10000, 90)]


def tool_rows(n):
    out = []
    ask = [("How much does M-Pesa charge to send {a} shillings?"),
           ("M-Pesa inatoza pesa ngapi kutuma shilingi {a}?"),
           ("Nikituma {a} bob kwa M-Pesa nitakatwa ngapi?")]
    for _ in range(n // 2):
        lo, hi, _f = random.choice(MPESA)
        a = random.randint(lo, hi)
        out.append(_pair(random.choice(ask).format(a=a),
                         {"tool": "mpesa_tariff", "args": {"amount": a, "txn_type": "send"}}))
    verbs = [
        ("I spent {a} on lunch today", {"tool": "ledger_add", "args": {"title": "Lunch", "amount": -1, "category": "Food"}}),
        ("Nimetumia {a} kwa chakula leo", {"tool": "ledger_add", "args": {"title": "Chakula", "amount": -1, "category": "Food"}}),
        ("Remind me to submit the assignment on Friday", {"tool": "task_add", "args": {"title": "Submit assignment", "due": "Friday"}}),
        ("Niwekee reminder ya kusubmit assignment Friday", {"tool": "task_add", "args": {"title": "Submit assignment", "due": "Friday"}}),
        ("Plan my day", {"tool": "plan_day", "args": {"date": "today"}}),
        ("Give me the campus emergency numbers", {"tool": "safety_contacts", "args": {"category": "emergency"}}),
        ("What's the fare from Embu university to town in the evening?", {"tool": "matatu_fare", "args": {"route": "UoEm-Embu town", "peak": True}}),
    ]
    while len(out) < n:
        q, call = random.choice(verbs)
        a = random.randint(50, 3000)
        call = json.loads(json.dumps(call).replace("-1", str(-a)))
        out.append(_pair(q.format(a=a), call))
    return out


# ------------------------------------------------------------ data: extraction
def extraction_rows(n):
    out, months = [], {"August": 8, "September": 9, "January": 1}
    for _ in range(n):
        bal = random.randint(3, 40) * 1000
        m = random.choice(list(months)); d = random.randint(1, 28)
        doc = (f"UNIVERSITY OF EMBU\nFEE STATEMENT\nBALANCE DUE: KES {bal}\n"
               f"Payment deadline: {d} {m} 2026\nPay via the student portal before exams.")
        res = {"summary": f"University of Embu fee statement. Balance KES {bal}, due {d} {m} 2026.",
               "fields": {"Balance": f"KES {bal}", "Due date": f"{d} {m} 2026"},
               "steps": ["Log in to the student portal", "Pay before the deadline", "Keep the receipt"],
               "deadlines": [{"title": "Fee balance due", "dueAt": f"2026-{months[m]:02d}-{d:02d}"}],
               "citations": [{"source": "UoEm Fee Structure 2024/25", "chunk": "Balances are due before exam cards are issued."}],
               "confidence": round(random.uniform(0.7, 0.95), 2), "topicSensitive": True}
        out.append(_pair(f"[image of a document]\n{doc}", res,
                         sysx=" Extract the document into strict JSON."))
    return out


# ---------------------------------------------------------------- data: kiembu
KIEMBU = [("Wĩ mwega?", "How are you?", "U hali gani?"),
          ("Ndĩ mwega", "I am well", "Niko poa"),
          ("Nĩ wega", "Thank you", "Asante"),
          ("Ũrĩ na kĩĩ?", "What is up?", "Una nini?"),
          ("Thiĩ na thayũ", "Go in peace", "Nenda kwa amani")]


def kiembu_rows():
    return [_pair(f'How do you say "{en}" in Kiembu?',
                  f'In Kiembu: "{ki}" (Kiswahili: {sw}).', raw=True)
            for ki, en, sw in KIEMBU]


# ----------------------------------------------------------- data: public SW
def public_rows(limit=1500):
    try:
        from datasets import load_dataset
        out = []
        ds = load_dataset("CohereForAI/aya_collection_language_split", "swahili",
                          split="train", streaming=True)
        for i, r in enumerate(ds):
            if i >= limit:
                break
            inp, tgt = r.get("inputs"), r.get("targets")
            if inp and tgt:
                out.append(_pair(str(inp), str(tgt), raw=True))
        print(f"  + public Swahili (Aya): {len(out)} rows")
        return out
    except Exception as e:
        print(f"  ! public Swahili skipped: {e}")
        return []


# ------------------------------------------------------------------- helpers
def _pair(user, model, sysx="", raw=False):
    content = model if raw else json.dumps(model, ensure_ascii=False)
    return {"messages": [{"role": "system", "content": SYSTEM + sysx},
                         {"role": "user", "content": user},
                         {"role": "model", "content": content}]}


def to_text(msgs):
    system, parts = "", []
    for m in msgs:
        if m["role"] == "system":
            system = m["content"]
        elif m["role"] == "user":
            u = (system + "\n\n" + m["content"]).strip() if system else m["content"]
            parts.append(f"<start_of_turn>user\n{u}<end_of_turn>\n"); system = ""
        else:
            parts.append(f"<start_of_turn>model\n{m['content']}<end_of_turn>\n")
    return "".join(parts)


# ------------------------------------------------------------------- pipeline
def build_dataset():
    print("Building dataset…")
    data = tool_rows(1200) + extraction_rows(600) + kiembu_rows() + public_rows(1500)
    random.shuffle(data)
    n_eval = max(60, len(data) // 12)
    print(f"  total {len(data)} rows  (train {len(data)-n_eval} / eval {n_eval})")
    return data[n_eval:], data[:n_eval]


def train(train_rows):
    from unsloth import FastModel
    from trl import SFTTrainer, SFTConfig
    from datasets import Dataset

    print(f"Loading {BASE_ID} …")
    model, tok = FastModel.from_pretrained(model_name=BASE_ID, max_seq_length=MAX_SEQ,
                                           load_in_4bit=True, full_finetuning=False)
    model = FastModel.get_peft_model(
        model, r=16, lora_alpha=16, lora_dropout=0.0,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj",
                        "gate_proj", "up_proj", "down_proj"],
        use_gradient_checkpointing="unsloth", random_state=3407)

    ds = Dataset.from_dict({"text": [to_text(r["messages"]) for r in train_rows]})
    max_steps = int(os.environ.get("MAX_STEPS", "0"))
    args = SFTConfig(dataset_text_field="text", per_device_train_batch_size=8,
                     gradient_accumulation_steps=2, warmup_ratio=0.03,
                     num_train_epochs=2, learning_rate=2e-4, weight_decay=0.01,
                     logging_steps=10, optim="adamw_8bit", seed=3407,
                     max_seq_length=MAX_SEQ, output_dir="out/adapter", report_to="none",
                     **({"max_steps": max_steps} if max_steps > 0 else {}))
    SFTTrainer(model=model, tokenizer=tok, train_dataset=ds, args=args).train()
    return model, tok


def merge_push(model, tok):
    from huggingface_hub import whoami
    user = whoami(token=HF_TOKEN)["name"]
    repo = os.environ.get("HF_REPO", f"{user}/gemma-4-tcc-e4b")
    print(f"Merging + pushing to https://huggingface.co/{repo} …")
    model.push_to_hub_merged(repo, tok, save_method="merged_16bit", token=HF_TOKEN)
    try:
        model.push_to_hub(repo + "-lora", token=HF_TOKEN)
    except Exception as e:
        print(f"  (adapter push skipped: {e})")
    return repo


def quick_eval(model, tok, eval_rows):
    from unsloth import FastModel
    FastModel.for_inference(model)
    known = {"mpesa_tariff", "ledger_add", "budget_make", "matatu_fare",
             "task_add", "plan_day", "set_reminder", "safety_contacts"}
    ok = tot = fh = ft = 0
    for r in eval_rows[:60]:
        tgt = r["messages"][-1]["content"]
        text = to_text(r["messages"][:-1]) + "<start_of_turn>model\n"
        # Gemma 4 uses a multimodal processor whose first positional arg is images,
        # so text MUST be passed by keyword.
        ids = tok(text=text, return_tensors="pt").to(model.device)
        out = model.generate(**ids, max_new_tokens=200, do_sample=False)
        pred = tok.decode(out[0][ids["input_ids"].shape[1]:], skip_special_tokens=True)
        if '"tool"' in tgt:
            tot += 1
            try:
                if json.loads(re.search(r"\{.*\}", pred, re.S).group()).get("tool") in known:
                    ok += 1
            except Exception:
                pass
        elif '"fields"' in tgt:
            try:
                exp = json.loads(tgt)["fields"]
                got = json.loads(re.search(r"\{.*\}", pred, re.S).group()).get("fields", {})
                for k in exp:
                    ft += 1; fh += (k in got)
            except Exception:
                ft += len(json.loads(tgt).get("fields", {}))
    line = (f"Fine-tuned eval — tool-JSON valid: {100*ok/max(1,tot):.0f}% (n={tot}) | "
            f"extraction field acc: {100*fh/max(1,ft):.0f}% (n={ft})")
    print(line)
    os.makedirs("out", exist_ok=True)
    open("out/results.md", "w").write("# TCC fine-tune eval\n\n" + line + "\n")


def main():
    train_rows, eval_rows = build_dataset()
    model, tok = train(train_rows)
    repo = merge_push(model, tok)
    quick_eval(model, tok, eval_rows)
    print("\n✅ Done.")
    print(f"   Model: https://huggingface.co/{repo}")
    print("   Next: point the app's model_manifest / Config.defaultModelUrl at it,")
    print("   and run the on-device conversion (gemma_model/scripts/4_convert_ondevice.py).")


if __name__ == "__main__":
    main()
