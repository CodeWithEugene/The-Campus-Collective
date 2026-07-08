"""Build the TCC fine-tuning dataset.

Three sources, mixed into data/train.jsonl + data/eval.jsonl (chat format):
  1. Programmatic tool-calling + doc-extraction pairs (deterministic, known-correct).
  2. Public Swahili SFT data (Aya, Inkuba-instruct) — general instruction-following.
  3. Optional teacher distillation (Gemma 4 26B/31B via vLLM) for trilingual chat.

Each row: {"messages": [{"role": "user"|"model"|"system", "content": ...}]}
matching Gemma 4's chat template.

Usage:
  python scripts/1_generate_data.py               # sources 1 + 2
  python scripts/1_generate_data.py --distill     # also source 3 (needs GPU)
"""
import argparse, json, os, random, yaml

random.seed(3407)
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_cfg():
    with open(os.path.join(ROOT, "config.yaml")) as f:
        return yaml.safe_load(f)


SYSTEM = (
    "You are TCC, an offline campus assistant for University of Embu students. "
    "You reply in the user's language (English, Kiswahili or Sheng), stay concise "
    "and practical, and call tools when a task needs real computation or data."
)

# ---- Source 1a: tool-calling pairs (from the app's real tool schemas) ----

MPESA_BANDS = [(101, 500, 7), (501, 1000, 13), (1001, 1500, 23), (1501, 2500, 33),
               (2501, 3500, 53), (3501, 5000, 57), (5001, 7500, 78), (7501, 10000, 90)]


def tool_examples(n):
    out = []
    templates = [
        ("en", "How much does M-Pesa charge to send {amt} shillings?"),
        ("sw", "M-Pesa inatoza pesa ngapi kutuma shilingi {amt}?"),
        ("sheng", "Nikituma {amt} bob kwa M-Pesa nitakatwa ngapi?"),
    ]
    for _ in range(n // 2):
        lo, hi, fee = random.choice(MPESA_BANDS)
        amt = random.randint(lo, hi)
        lang, q = random.choice(templates)
        call = {"tool": "mpesa_tariff", "args": {"amount": amt, "txn_type": "send"}}
        out.append({"messages": [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": q.format(amt=amt)},
            {"role": "model", "content": json.dumps(call)},
        ]})
    # ledger / budget / matatu / task tools
    verbs = [
        ("en", "I spent {amt} on lunch today", {"tool": "ledger_add", "args": {"title": "Lunch", "amount": "-{amt}", "category": "Food"}}),
        ("sw", "Nimetumia {amt} kwa chakula leo", {"tool": "ledger_add", "args": {"title": "Chakula", "amount": "-{amt}", "category": "Food"}}),
        ("en", "Remind me to submit the assignment on Friday", {"tool": "task_add", "args": {"title": "Submit assignment", "due": "Friday"}}),
        ("sheng", "Niwekee reminder ya kusubmit assignment Friday", {"tool": "task_add", "args": {"title": "Submit assignment", "due": "Friday"}}),
        ("en", "Plan my day", {"tool": "plan_day", "args": {"date": "today"}}),
        ("en", "Give me the campus emergency numbers", {"tool": "safety_contacts", "args": {"category": "emergency"}}),
    ]
    for _ in range(n - len(out)):
        lang, q, call = random.choice(verbs)
        amt = random.randint(50, 3000)
        q = q.format(amt=amt)
        call = json.loads(json.dumps(call).replace("{amt}", str(amt)))
        out.append({"messages": [
            {"role": "system", "content": SYSTEM},
            {"role": "user", "content": q},
            {"role": "model", "content": json.dumps(call)},
        ]})
    return out


# ---- Source 1b: document-extraction pairs (strict JSON, ScanResult shape) ----

def extraction_examples(n):
    out = []
    for i in range(n):
        bal = random.randint(3, 40) * 1000
        months = {"August": 8, "September": 9, "January": 1}
        due_m = random.choice(list(months))
        due_d = random.randint(1, 28)
        doc = (f"UNIVERSITY OF EMBU\nFEE STATEMENT\nStudent: E{random.randint(20,25)}/{random.randint(1000,9999)}/24\n"
               f"Programme fees this semester: KES {bal + random.randint(1,20)*1000}\n"
               f"Amount paid: KES {random.randint(1,20)*1000}\nBALANCE DUE: KES {bal}\n"
               f"Payment deadline: {due_d} {due_m} 2026\nPay via the student portal before exams.")
        result = {
            "summary": f"This is a University of Embu fee statement. Your outstanding balance is KES {bal}, due {due_d} {due_m} 2026.",
            "fields": {"Balance": f"KES {bal}", "Due date": f"{due_d} {due_m} 2026"},
            "steps": ["Log in to the student portal", "Pay the balance before the deadline", "Keep the receipt"],
            "deadlines": [{"title": "Fee balance due", "dueAt": f"2026-{months[due_m]:02d}-{due_d:02d}"}],
            "citations": [{"source": "UoEm Fee Structure 2024/25", "chunk": "Balances are due before examination cards are issued."}],
            "confidence": round(random.uniform(0.7, 0.95), 2),
            "topicSensitive": True,
        }
        out.append({"messages": [
            {"role": "system", "content": SYSTEM + " Extract the document into strict JSON."},
            {"role": "user", "content": f"[image of a document]\n{doc}"},
            {"role": "model", "content": json.dumps(result, ensure_ascii=False)},
        ]})
    return out


# ---- Source 2: public Swahili SFT data ----

def public_examples(cfg):
    from datasets import load_dataset
    rows = []
    for src in cfg["data"]["public_sources"]:
        try:
            ds = load_dataset(src["id"], src.get("config"), split="train", streaming=True)
            for i, r in enumerate(ds):
                if i >= src["max_rows"]:
                    break
                inp = r.get("inputs") or r.get("instruction") or r.get("prompt") or ""
                tgt = r.get("targets") or r.get("output") or r.get("response") or ""
                if inp and tgt:
                    rows.append({"messages": [
                        {"role": "user", "content": str(inp)},
                        {"role": "model", "content": str(tgt)},
                    ]})
            print(f"  + {src['id']}: pulled up to {src['max_rows']} rows")
        except Exception as e:
            print(f"  ! skipped {src['id']}: {e}")
    return rows


# ---- Source 2b: Kiembu phrasebook ----

def kiembu_examples(cfg):
    path = os.path.join(ROOT, cfg["data"]["kiembu_path"])
    if not os.path.exists(path):
        return []
    out = []
    for line in open(path, encoding="utf-8"):
        e = json.loads(line)
        out.append({"messages": [
            {"role": "user", "content": f"How do you say \"{e['english']}\" in Kiembu?"},
            {"role": "model", "content": f"In Kiembu: \"{e['kiembu']}\" (Kiswahili: {e['swahili']})."},
        ]})
    return out


# ---- Source 3: teacher distillation (optional) ----

def distill_examples(cfg):
    from vllm import LLM, SamplingParams
    seeds = []
    for line in open(os.path.join(ROOT, "data/seeds/trilingual_chat_seeds.jsonl"), encoding="utf-8"):
        seeds.append(json.loads(line))
    llm = LLM(model=cfg["distill"]["teacher_id"], dtype="bfloat16", trust_remote_code=True)
    sp = SamplingParams(temperature=0.8, max_tokens=cfg["distill"]["max_new_tokens"])
    out = []
    for s in seeds:
        for lang in ["English", "Kiswahili", "Sheng"]:
            prompt = (f"{SYSTEM}\nScenario: {s['scenario']}\n"
                      f"Write a realistic student question and TCC's helpful answer in {lang}. "
                      f"Return as: Q: <question>\\nA: <answer>")
            for _ in range(cfg["distill"]["per_seed"]):
                gen = llm.generate(prompt, sp)[0].outputs[0].text
                if "A:" in gen:
                    q = gen.split("A:")[0].replace("Q:", "").strip()
                    a = gen.split("A:", 1)[1].strip()
                    if q and a:
                        out.append({"messages": [
                            {"role": "system", "content": SYSTEM},
                            {"role": "user", "content": q},
                            {"role": "model", "content": a},
                        ]})
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--distill", action="store_true")
    args = ap.parse_args()
    cfg = load_cfg()

    print("Generating programmatic tool-calling examples…")
    data = tool_examples(cfg["data"]["tool_examples"])
    print("Generating document-extraction examples…")
    data += extraction_examples(cfg["data"]["extraction_examples"])
    print("Loading public Swahili SFT data…")
    data += public_examples(cfg)
    print("Adding Kiembu phrasebook…")
    data += kiembu_examples(cfg)
    if args.distill or cfg["distill"]["enabled"]:
        print("Teacher-distilling trilingual chat (GPU)…")
        data += distill_examples(cfg)

    random.shuffle(data)
    n_eval = max(50, len(data) // 10)
    eval_rows, train_rows = data[:n_eval], data[n_eval:]

    os.makedirs(os.path.join(ROOT, "data"), exist_ok=True)
    for name, rows in [("train", train_rows), ("eval", eval_rows)]:
        p = os.path.join(ROOT, f"data/{name}.jsonl")
        with open(p, "w", encoding="utf-8") as f:
            for r in rows:
                f.write(json.dumps(r, ensure_ascii=False) + "\n")
        print(f"wrote {len(rows)} rows -> {p}")


if __name__ == "__main__":
    main()
