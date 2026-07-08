"""QLoRA fine-tune Gemma 4 E4B with Unsloth on the molab RTX Pro 6000.

Loads data/train.jsonl (chat format), trains a LoRA adapter, saves to out/adapter/.
Runs comfortably in <16 GB VRAM — the 96 GB GPU has enormous headroom, so you can
raise batch_size / max_seq_len in config.yaml if you want.

  python scripts/2_train_qlora.py
"""
import os, yaml
from datasets import load_dataset

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cfg = yaml.safe_load(open(os.path.join(ROOT, "config.yaml")))


def main():
    from unsloth import FastModel
    from unsloth.chat_templates import get_chat_template
    from trl import SFTTrainer, SFTConfig

    model, tokenizer = FastModel.from_pretrained(
        model_name=cfg["model"]["base_id"],
        max_seq_length=cfg["model"]["max_seq_len"],
        load_in_4bit=cfg["model"]["load_in_4bit"],
        full_finetuning=False,
    )

    model = FastModel.get_peft_model(
        model,
        r=cfg["lora"]["r"],
        lora_alpha=cfg["lora"]["alpha"],
        lora_dropout=cfg["lora"]["dropout"],
        target_modules=cfg["lora"]["target_modules"],
        use_gradient_checkpointing="unsloth",
        random_state=cfg["train"]["seed"],
    )

    tokenizer = get_chat_template(tokenizer, chat_template="gemma-4")

    ds = load_dataset("json", data_files=os.path.join(ROOT, cfg["data"]["train_path"]), split="train")

    def fmt(batch):
        texts = [
            tokenizer.apply_chat_template(m, tokenize=False, add_generation_prompt=False)
            for m in batch["messages"]
        ]
        return {"text": texts}

    ds = ds.map(fmt, batched=True, remove_columns=ds.column_names)

    trainer = SFTTrainer(
        model=model,
        tokenizer=tokenizer,
        train_dataset=ds,
        args=SFTConfig(
            dataset_text_field="text",
            per_device_train_batch_size=cfg["train"]["batch_size"],
            gradient_accumulation_steps=cfg["train"]["grad_accum"],
            warmup_ratio=cfg["train"]["warmup_ratio"],
            num_train_epochs=cfg["train"]["epochs"],
            learning_rate=cfg["train"]["lr"],
            weight_decay=cfg["train"]["weight_decay"],
            logging_steps=10,
            optim="adamw_8bit",
            seed=cfg["train"]["seed"],
            output_dir=os.path.join(ROOT, cfg["train"]["output_dir"]),
            report_to="none",
        ),
    )
    trainer.train()

    out = os.path.join(ROOT, cfg["train"]["output_dir"])
    model.save_pretrained(out)
    tokenizer.save_pretrained(out)
    print(f"LoRA adapter saved -> {out}")


if __name__ == "__main__":
    main()
