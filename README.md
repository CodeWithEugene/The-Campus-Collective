# The Campus Collective (TCC)

**A collective of AI agents in every student's pocket — fully offline, fully on-device, kwa lugha yetu.**

TCC is an Android-first Flutter app that runs **Gemma 4 entirely on the student's own phone** — no internet, no server, no data bundles after setup. Four specialist agents help Kenyan university students survive campus life: decode fee statements and HELB letters, turn photographed notes into quizzes, plan budgets around an M-Pesa reality, and organize the day around classes and deadlines.

> Built for **"Build with Gemma: The Campus Survival Guide"** — GDG on Campus, University of Embu · July 17, 2026 · [Kaggle hackathon](https://www.kaggle.com/competitions/build-with-gemma-gdg-embu)

## 📲 Download the app

**[⬇️ Download the APK (v1.0.0, Android arm64, ~31 MB)](https://github.com/CodeWithEugene/The-Campus-Collective/releases/latest/download/app-release.apk)**

1. Download the APK on your Android phone and open it.
2. If Play Protect warns about an unknown app, tap **More details → Install anyway** (the APK is unsigned-for-store, built straight from this repo).
3. On first run, TCC downloads its Gemma 4 model (**2.6–3.6 GB — use Wi-Fi**). After that, everything runs offline forever — try it in airplane mode.

All releases: [GitHub Releases](https://github.com/CodeWithEugene/The-Campus-Collective/releases)

## The problem

For a student at the University of Embu, campus survival runs on a budget Tecno/Infinix phone and scarce data bundles:

- **HELB/HEF chaos** — funding-model court rulings, delayed disbursements, portals saying "successful" with no money, and fee letters written in bureaucratese.
- **Information scattered** across WhatsApp groups: fee deadlines, timetables, hostel notices.
- **Money pressure** — HELB installments, side hustles, M-Pesa charges, matatu fares — with no tool that understands any of it.
- **Cloud AI doesn't fit** — it needs bundles, sends private documents to servers, and doesn't speak the way students actually talk.

## The solution: four agents, one chat

| Agent | What it does |
|---|---|
| 📚 **Somo** *(study)* | Photograph handwritten/printed notes or past papers → summary, 5-question quiz, and flashcards, explained in Sheng-flavoured Swahili. Share to WhatsApp. |
| 📜 **Karani** *(bureaucracy)* | Photograph a fee statement, HELB letter, timetable, or hostel notice → plain-Swahili explanation, structured fields, extracted deadlines (handed to Ratiba), with every claim **cited to real University of Embu documents** via on-device RAG. |
| 💸 **Hustle** *(money)* | Function-calling money agent: AI budget maker ("Nimepata HELB 15k…" → a monthly budget), expense tracking with receipt scanning, M-Pesa tariff and matatu-fare tools, weekly insight cards, and a Sheng copywriter for WhatsApp-Status side-hustle ads. |
| 🗓️ **Ratiba** *(planner)* | "Panga siku yangu" → builds the day from your photographed class timetable, Karani's extracted deadlines, and your tasks → prioritized plan with local reminders. |

One chat box routes to the right agent automatically; each agent only sees its own 2–4 tools, which keeps edge-model function calling reliable. A Safety screen keeps campus and national emergency contacts (Police 999/112, GBV 1195, campus security) available with zero internet.

## Why Gemma 4 — every differentiator, load-bearing

| Gemma 4 capability | How TCC uses it |
|---|---|
| **On-device edge models** (E2B ≈ 2.6 GB, E4B ≈ 3.65 GB `.litertlm`) | Runs via LiteRT-LM / `flutter_gemma` on the 6–8 GB RAM phones students actually own. The whole demo works in airplane mode. |
| **Multimodal vision** | Somo reads notes and past papers; Karani reads fee statements, HELB letters, receipts, timetables — straight from the camera. |
| **Native function calling** | Hustle and Ratiba call real Dart tools (`mpesa_tariff`, `budget_make`, `matatu_fare`, `task_add`, `plan_day`, `set_reminder`, `safety_contacts`, `ledger_add`) with flat JSON schemas. |
| **140+ languages** | English/Kiswahili/Sheng code-switching, plus our fine-tune (below). |
| **Apache 2.0** | We fine-tuned Gemma 4 and host our own model **ungated** on Hugging Face — no login friction on first-run download. |

## Our fine-tuned model: `gemma-4-tcc`

We fine-tuned **Gemma 4 E4B** on an RTX Pro 6000 (96 GB, molab.marimo.io) using **Unsloth QLoRA** — loss 1.79 → 0.57 over 380 steps on ~3.3k examples. The dataset mixes:

1. **Programmatic pairs** generated from the app's real tool schemas and content packs (tool calls + document extraction with known-correct outputs).
2. **Teacher distillation** — Gemma 4 26B/31B generating trilingual campus-scenario conversations.
3. **Public Swahili SFT** (Aya, Inkuba-instruct) plus our **hand-collected Kiembu phrasebook** — Embu's actual local language has essentially zero public NLP data, so we collected our own with students.

| Artifact | Link |
|---|---|
| Merged fine-tuned model | [`Eugeniuss/gemma-4-tcc-e4b`](https://huggingface.co/Eugeniuss/gemma-4-tcc-e4b) |
| LoRA adapter | [`Eugeniuss/gemma-4-tcc-e4b-lora`](https://huggingface.co/Eugeniuss/gemma-4-tcc-e4b-lora) |
| On-device `.litertlm` build | [`Eugeniuss/gemma-4-tcc-e4b-litertlm`](https://huggingface.co/Eugeniuss/gemma-4-tcc-e4b-litertlm) |

The full pipeline (data generation → QLoRA training → merge & push → `litert-torch` on-device conversion → before/after eval) is in [`gemma_model/`](gemma_model/). The shipped app runs stock **Gemma 4 E2B** (safe on 6 GB phones); the fine-tuned E4B build swaps in per-device via a remote model manifest once its on-device conversion is published — model upgrades need no app update.

## Architecture

```
┌─────────────────────────── The phone (everything lives here) ───────────────────────────┐
│  Flutter app (Material 3, AMOLED dark)                                                  │
│  ├─ Chat router → Somo · Karani · Hustle · Ratiba (per-agent tool scoping)              │
│  ├─ Gemma 4 E4B/E2B via flutter_gemma (LiteRT-LM) — vision + function calling          │
│  ├─ On-device RAG: EmbeddingGemma + sqlite-vec over the UoEm corpus (cited answers)     │
│  ├─ Drift/SQLite: budgets, transactions, tasks, deadlines, scans, chats                 │
│  └─ Bundled content packs: M-Pesa tariffs · matatu fares · safety contacts · Kiembu     │
└──────────────────────────────────────────────────────────────────────────────────────────┘
                     │ (optional, online-only, no user data ever goes up)
┌────────────────────▼────────────────────┐
│  Supabase (distribution only, RLS)      │   model_manifest → which model URL per device
│  content_packs → refreshable JSON       │   feedback_reports → anonymous, insert-only
└─────────────────────────────────────────┘
```

**Privacy is architectural, not a promise**: notes, scans, budgets, chats, and every AI inference stay in on-device SQLite. The backend can only ship things *down* (model manifest, content packs) and receive anonymous feedback. The app is fully functional with the backend unreachable.

## Repository layout

```
app/           Flutter app — 16k+ lines of Dart, 40+ screens, dark AMOLED design system
  lib/features/   onboarding · chat · somo · karani · hustle · ratiba · mimi · settings
  lib/llm/        GemmaService interface + engine (flutter_gemma swap point)
  lib/data/       Drift database · content packs · resumable model downloader
data/content/  Ground-truth JSON: M-Pesa tariffs, matatu fares, safety contacts,
               UoEm corpus, hand-collected Kiembu phrasebook
gemma_model/   Full fine-tuning pipeline (Unsloth QLoRA → HF → litert-torch conversion)
supabase/      Distribution-only backend migration (4 tables, strict RLS)
project.md     The complete build strategy, design system, and 60+ page UX inventory
```

## Build from source

Requirements: Flutter 3.44+ (Dart ≥ 3.12, required by `flutter_gemma`), Android SDK.

```bash
cd app
flutter pub get
flutter analyze                 # → No issues found
flutter build apk --release --target-platform android-arm64
# → build/app/outputs/flutter-apk/app-release.apk
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

To retrain the model, see [`gemma_model/README.md`](gemma_model/README.md).

## Honest limitations

- **Kiembu** is a hand-collected phrasebook layer (greetings, campus terms), not a trained language — no public Kiembu dataset exists, so we started one.
- **Sheng** fluency is prompt/fine-tune level, not native — reviewed by native speakers.
- **Hardware floor**: ~6 GB RAM for E2B. Budget MediaTek chips fall back to CPU (~2–5 tok/s) — usable for short answers, slower than flagships, still fully offline.
- Sensitive outputs (fees, HELB, deadlines) carry a low-confidence banner and "verify with the office" guidance; official figures are RAG-cited to source documents, never hard-coded.

## Team & license

Built by **Eugene Mutembei** ([@CodeWithEugene](https://github.com/CodeWithEugene)) for GDG on Campus University of Embu, 2026.

- Code: [MIT License](LICENSE)
- Gemma 4 & our fine-tuned models: Apache 2.0