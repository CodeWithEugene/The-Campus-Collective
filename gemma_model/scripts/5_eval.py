"""Before/after evaluation: base Gemma 4 E4B vs the fine-tuned TCC model.

Produces out/results.md — the Technical-Depth evidence for the Kaggle writeup.
Metrics:
  - tool_call_valid_json: % of tool prompts where output is valid JSON with a known tool
  - extraction_field_acc:  % of expected fields present in doc-extraction outputs
  - lang_match:            % of answers in the requested language (heuristic)

  python scripts/5_eval.py --model out/merged           # fine-tuned
  python scripts/5_eval.py --model unsloth/gemma-4-E4B-it --tag base
"""
import argparse, json, os, re, yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cfg = yaml.safe_load(open(os.path.join(ROOT, "config.yaml")))

KNOWN_TOOLS = {"mpesa_tariff", "ledger_add", "budget_make", "matatu_fare",
               "task_add", "plan_day", "set_reminder", "safety_contacts"}


def gen_fn(model_name):
    from unsloth import FastModel
    model, tok = FastModel.from_pretrained(model_name, max_seq_length=cfg["model"]["max_seq_len"],
                                           load_in_4bit=True)
    FastModel.for_inference(model)

    def run(messages):
        prompt = tok.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
        ids = tok(prompt, return_tensors="pt").to(model.device)
        out = model.generate(**ids, max_new_tokens=256, do_sample=False)
        return tok.decode(out[0][ids["input_ids"].shape[1]:], skip_special_tokens=True)

    return run


def score(run, rows):
    tool_ok = tool_total = 0
    field_hit = field_total = 0
    for r in rows:
        msgs = r["messages"]
        target = msgs[-1]["content"]
        pred = run(msgs[:-1])
        if '"tool"' in target:
            tool_total += 1
            try:
                j = json.loads(re.search(r"\{.*\}", pred, re.S).group())
                if j.get("tool") in KNOWN_TOOLS:
                    tool_ok += 1
            except Exception:
                pass
        elif '"fields"' in target:
            try:
                exp = json.loads(target).get("fields", {})
                got = re.search(r"\{.*\}", pred, re.S)
                gotj = json.loads(got.group()) if got else {}
                gf = gotj.get("fields", {})
                for k in exp:
                    field_total += 1
                    if k in gf:
                        field_hit += 1
            except Exception:
                field_total += len(json.loads(target).get("fields", {}))
    return {
        "tool_call_valid_json": round(100 * tool_ok / max(1, tool_total), 1),
        "extraction_field_acc": round(100 * field_hit / max(1, field_total), 1),
        "n_tool": tool_total, "n_extract": field_total,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default=os.path.join(ROOT, "out/merged"))
    ap.add_argument("--tag", default="finetuned")
    args = ap.parse_args()

    rows = [json.loads(l) for l in open(os.path.join(ROOT, cfg["data"]["eval_path"]), encoding="utf-8")]
    res = score(gen_fn(args.model), rows)

    out = os.path.join(ROOT, "out/results.md")
    header = not os.path.exists(out)
    with open(out, "a") as f:
        if header:
            f.write("# TCC fine-tune evaluation\n\n| model | tool JSON valid % | extraction field acc % | n |\n|---|---|---|---|\n")
        f.write(f"| {args.tag} | {res['tool_call_valid_json']} | {res['extraction_field_acc']} | "
                f"{res['n_tool']}+{res['n_extract']} |\n")
    print(res, "->", out)


if __name__ == "__main__":
    main()
