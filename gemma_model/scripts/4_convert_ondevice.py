"""Convert the merged fine-tuned model to an on-device format for flutter_gemma.

⚠️ THIS IS THE HARD STEP (README §5). Do it in a SEPARATE virtualenv from Unsloth
(ai-edge-torch pins its own torch). Iterate on E2B first — it converts faster.

The real, documented pipeline (Google AI Edge, 2026):
  merged HF model  --ai-edge-torch-->  .tflite  --mediapipe genai bundler-->  .task
                    (quantize int8/int4)          (adds tokenizer + stop tokens)
flutter_gemma loads the resulting .task (or .litertlm) on Android/iOS.

Official references (check for the CURRENT Gemma 4 converter before running):
  - https://ai.google.dev/edge/litert-lm            (LiteRT-LM overview)
  - https://developers.google.com/edge/litert-lm/tutorials/convert-and-run
  - https://github.com/google-ai-edge/ai-edge-torch  (generative/examples/*)

This script is a RUNBOOK: it wires the documented calls and fails loudly with the
next action if the converter for a given model family isn't present in your installed
ai-edge-torch version (the Gemma 4 example module name changes across releases).
"""
import argparse, os, subprocess, sys, yaml

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cfg = yaml.safe_load(open(os.path.join(ROOT, "config.yaml")))


def convert(merged_dir, out_dir, quant):
    os.makedirs(out_dir, exist_ok=True)
    try:
        import ai_edge_torch  # noqa
        from ai_edge_torch.generative.utilities import converter  # noqa
    except Exception as e:
        sys.exit(
            "ai-edge-torch not installed or API moved.\n"
            "  pip install ai-edge-torch ai-edge-litert mediapipe\n"
            f"  ({e})\n"
            "Then find the Gemma 4 converter under ai_edge_torch/generative/examples/ "
            "for your installed version and call its convert_to_tflite()."
        )
    # The generative example converters expose a convert helper per model family.
    # For Gemma 4 the module is typically ai_edge_torch.generative.examples.gemma4.
    # We shell out to the packaged example so we always use the installed version's API:
    tflite = os.path.join(out_dir, "gemma-4-tcc.tflite")
    cmd = [
        sys.executable, "-m", "ai_edge_torch.generative.examples.gemma4.convert_to_tflite",
        "--checkpoint_path", merged_dir,
        "--output_path", tflite,
        "--quantize", quant,          # e.g. "dynamic_int8" or "int4"
        "--prefill_seq_len", "1024",
        "--kv_cache_max_len", str(cfg["model"]["max_seq_len"]),
    ]
    print("→", " ".join(cmd))
    r = subprocess.run(cmd)
    if r.returncode != 0:
        sys.exit(
            "Converter module not found for this ai-edge-torch version.\n"
            "List available example converters with:\n"
            "  python -c \"import ai_edge_torch.generative.examples as e, os; "
            "print(os.listdir(os.path.dirname(e.__file__)))\"\n"
            "and use the gemma-4 (or nearest gemma) example's convert entrypoint."
        )
    return tflite


def bundle_task(tflite, merged_dir, out_dir):
    """Wrap the .tflite + tokenizer into a MediaPipe .task bundle (flutter_gemma loads it)."""
    try:
        from mediapipe.tasks.python.genai import bundler
    except Exception as e:
        sys.exit(f"Install mediapipe to bundle the .task ({e}).")
    task_path = os.path.join(out_dir, "gemma-4-tcc-e4b.task")
    config = bundler.BundleConfig(
        tflite_model=tflite,
        tokenizer_model=os.path.join(merged_dir, "tokenizer.model"),
        start_token="<start_of_turn>",
        stop_tokens=["<end_of_turn>"],
        output_filename=task_path,
        enable_bytes_to_unicode_mapping=False,
    )
    bundler.create_bundle(config)
    print(f"on-device bundle -> {task_path}")
    return task_path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--merged", default=os.path.join(ROOT, "out/merged"))
    ap.add_argument("--out", default=os.path.join(ROOT, "out/ondevice"))
    ap.add_argument("--quant", default="dynamic_int8")
    args = ap.parse_args()

    tflite = convert(args.merged, args.out, args.quant)
    bundle_task(tflite, args.merged, args.out)
    print(
        "\nNext: upload the .task (and/or .litertlm) to Hugging Face UNGATED, then set\n"
        "  model_manifest.url (Supabase, app §17) to its download URL.\n"
        "flutter_gemma downloads it on first run and runs it fully offline."
    )


if __name__ == "__main__":
    main()
