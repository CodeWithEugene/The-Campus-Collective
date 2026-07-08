"""TCC — convert the fine-tuned Gemma 4 E4B → on-device .litertlm, push to HF.

Run this AFTER tcc_train.py has pushed your merged model. Runs on molab (uv is
present there). Uses Google's real conversion tool `litert-torch` (verified July 2026
against Google's official convert-and-run tutorial + a Gemma-4-on-Android writeup).

⚠️ This is the finicky step. For a *multimodal* E4B model the exporter can be
imperfect outside the LoRA-trained layers. If the phone can't load the result, use
the fallback in the README (ship stock E2B .litertlm, demo the fine-tune via notebook).

Env:
  HF_TOKEN   your HF read+write token
  HF_MODEL   merged model repo (default Eugeniuss/gemma-4-tcc-e4b)
  OUT_REPO   on-device output repo (default {HF_MODEL}-litertlm)
"""
import os, subprocess, sys

HF_TOKEN = os.environ["HF_TOKEN"]
os.environ.setdefault("HF_HUB_DISABLE_XET", "1")
HF_MODEL = os.environ.get("HF_MODEL", "Eugeniuss/gemma-4-tcc-e4b")
OUT_REPO = os.environ.get("OUT_REPO", HF_MODEL + "-litertlm")
OUT_DIR = "/marimo/tcc_ondevice"


def sh(cmd, check=True):
    print("→", cmd)
    return subprocess.run(cmd, shell=True, check=check)


def main():
    # 1) convert merged HF model → .litertlm (multimodal E4B).
    #    uvx runs the tool without a persistent install (robust in a subprocess).
    sh(
        # --with pillow/torchvision: the multimodal export needs them for
        # AutoImageProcessor, but litert-torch-nightly doesn't declare them.
        "uvx --from litert-torch-nightly --with pillow --with torchvision "
        "litert-torch export_hf "
        f"--model={HF_MODEL} "
        f"--output_dir={OUT_DIR} "
        "--externalize_embedder "
        # int4 weights — int8 (dynamic_wi8_afp32) yields an ~8.3 GB bundle that
        # no target phone can hold; wi4 lands ~4 GB like litert-community's E4B.
        "--quantization_recipe dynamic_wi4_afp32 "
        '--vision_encoder_quantization_recipe "" '
        "--task image_text_to_text"
    )

    # 2) optional local sanity test (skip if litert-lm isn't installed).
    sh(f'uvx litert-lm run {OUT_DIR}/model.litertlm '
       '--prompt="Nikituma 1200 kwa M-Pesa nitakatwa ngapi?"', check=False)

    # 3) upload the on-device model to HF, UNGATED (Apache-2.0) so the app
    #    downloads it on first run with no login.
    # `huggingface-cli` is deprecated (and a no-op on molab) — use `hf`.
    sh(f"hf upload {OUT_REPO} {OUT_DIR} --repo-type model")

    print(f"\n✅ On-device model: https://huggingface.co/{OUT_REPO}")
    print("   Point the app's model URL at:")
    print(f"   https://huggingface.co/{OUT_REPO}/resolve/main/model.litertlm")


if __name__ == "__main__":
    main()
