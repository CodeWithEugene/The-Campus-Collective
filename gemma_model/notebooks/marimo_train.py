"""Marimo notebook for molab (RTX Pro 6000) — run the TCC fine-tune end to end.

Open in molab.marimo.io with the GPU attached, then run cells top to bottom.
Each cell shells out to the scripts/ so the notebook and CLI stay in sync.
"""
import marimo

app = marimo.App(width="medium")


@app.cell
def _():
    import subprocess, os
    ROOT = os.path.abspath(os.path.join(os.getcwd(), ".."))

    def sh(cmd):
        print("→", cmd)
        subprocess.run(cmd, shell=True, cwd=ROOT, check=True)

    return ROOT, sh


@app.cell
def _(sh):
    # 1. Install deps + log in to Hugging Face (paste token or set HF_TOKEN in .env).
    sh("pip install -q -r requirements.txt")
    return


@app.cell
def _(sh):
    # 2. Build the dataset. Add --distill to teacher-distill trilingual chat on the GPU.
    sh("python scripts/1_generate_data.py")
    return


@app.cell
def _(sh):
    # 3. QLoRA fine-tune Gemma 4 E4B (adapter -> out/adapter/).
    sh("python scripts/2_train_qlora.py")
    return


@app.cell
def _(sh):
    # 4. Merge the adapter and push the merged model to Hugging Face.
    sh("python scripts/3_merge_and_push.py --lora-only")
    return


@app.cell
def _(sh):
    # 5. Evaluate base vs fine-tuned -> out/results.md (the writeup evidence).
    sh("python scripts/5_eval.py --model unsloth/gemma-4-E4B-it --tag base")
    sh("python scripts/5_eval.py --model out/merged --tag finetuned")
    return


@app.cell
def _():
    # 6. On-device conversion (scripts/4_convert_ondevice.py) runs in a SEPARATE
    #    env (ai-edge-torch pins its own torch). See README §5 — do E2B first.
    return


if __name__ == "__main__":
    app.run()
