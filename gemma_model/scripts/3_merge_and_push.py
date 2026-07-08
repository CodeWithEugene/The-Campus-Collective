"""Merge the LoRA adapter into the base model and push to Hugging Face.

Merging is required because on-device conversion (LiteRT/MediaPipe) works from a
single merged checkpoint, not a separate adapter (see README §5).

  python scripts/3_merge_and_push.py            # merge + push merged model
  python scripts/3_merge_and_push.py --lora-only # also push the adapter alone
"""
import argparse, os, yaml
from dotenv import load_dotenv

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
load_dotenv(os.path.join(ROOT, ".env"))
cfg = yaml.safe_load(open(os.path.join(ROOT, "config.yaml")))
HF_TOKEN = os.environ.get("HF_TOKEN")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lora-only", action="store_true")
    args = ap.parse_args()

    from unsloth import FastModel

    adapter = os.path.join(ROOT, cfg["train"]["output_dir"])
    merged = os.path.join(ROOT, "out/merged")

    model, tokenizer = FastModel.from_pretrained(
        model_name=adapter,
        max_seq_length=cfg["model"]["max_seq_len"],
        load_in_4bit=False,          # load in 16-bit to merge cleanly
    )

    # Merge LoRA into base weights and save fp16 (Unsloth helper).
    model.save_pretrained_merged(merged, tokenizer, save_method="merged_16bit")
    print(f"merged model -> {merged}")

    if HF_TOKEN:
        model.push_to_hub_merged(
            cfg["hub"]["repo_id"], tokenizer,
            save_method="merged_16bit", token=HF_TOKEN,
            private=cfg["hub"]["private"],
        )
        print(f"pushed merged model -> https://huggingface.co/{cfg['hub']['repo_id']}")
        if args.lora_only:
            model.push_to_hub(cfg["hub"]["lora_repo_id"], token=HF_TOKEN,
                              private=cfg["hub"]["private"])
            print(f"pushed adapter -> https://huggingface.co/{cfg['hub']['lora_repo_id']}")
    else:
        print("No HF_TOKEN in .env — skipped push. Merged model is in out/merged/.")


if __name__ == "__main__":
    main()
