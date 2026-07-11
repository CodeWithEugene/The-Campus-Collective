# The Campus Collective (TCC) — Winning Strategy for "Build with Gemma: GDG Embu"

> Synthesized 2026-07-05 (updated same day: TCC identity + Android-first) from deep research: the
> official GDG + Kaggle pages (including Kaggle's internal competition API), Google's official
> hackathon-template rubric, Gemma 4 documentation, the Android on-device Gemma toolchain, prior
> Gemma hackathon winners, Kenyan/Embu ground truth, and a critical review of the AI-generated
> proposals (Campus Compass AI, Mwanga, CampusSync, POA). Unverified items are flagged.

---

## 1. TL;DR — the one-paragraph strategy

**The Campus Collective (TCC)** is a **mobile app (Flutter — Android first, iOS-ready)**: a
*collective* of specialist AI agents in a student's pocket, running **Gemma 4 E2B fully
on-device**. Four agents: **Somo** (photograph notes/past papers → summary + quiz), **Karani**
(photograph a fee statement / HELB-HEF letter → plain-Swahili explanation, extracted deadlines,
answers cited to real University of Embu documents via on-device RAG), **Hustle** (function-calling
money agent: smart budget & finance tracker, AI budget maker, M-Pesa tariff, matatu fare), and
**Ratiba** (AI day planner: deadlines + timetable → a planned day with reminders). It speaks Swahili/Sheng/English code-switch with a **hand-collected
Kiembu phrasebook layer** (Embu's actual language — one proposal wrongly said Kimeru). The entire
demo runs in **airplane mode on a real budget Android phone** — the exact profile of the Gemma 3n
Impact Challenge winner. Then spend disproportionate effort on what's actually scored: a ≤3-minute
story video (~70% of effective score), a proof-of-work Kaggle Writeup with cover image, and a
public repo + installable APK. Everything public, submitted (not draft) before **July 17, 21:00 UTC**.

---

## 2. Verified hackathon facts

### The event (GDG page, verified verbatim)
| Fact | Detail |
|---|---|
| Event | "Build with Gemma: The Campus Survival Guide", GDG on Campus University of Embu |
| Date | **July 17, 2026**, 9:00 AM – 4:00 PM EAT (6:00–13:00 UTC), virtual, one day |
| Brief (verbatim) | "Use the newly released **Gemma 4** models to create **AI agents, multimodal vision tools, or local-language bots** that make student life and the local hustle a little less chaotic." |
| Tone (verbatim) | "Tired of cringe AI wrappers? Come build something real." |
| Tracks | Beginner (prompt crafting) → advanced (**on-device model deployment**) |
| Organizers (likely judges) | Erick Mwangi (Lead), Faith Kiprono (Co-Lead), Martin Muchiri, Vickrose Gitau, Charles Muthui, Ephey Nyaga, Logan Nkirote, Phillip Wachira, Kendi Jackline |

### The Kaggle competition (verified via Kaggle's own competition API, comp ID 151430)
| Fact | Detail |
|---|---|
| Final deadline | **2026-07-17 21:00 UTC** = midnight EAT going into July 18 |
| Prize | USD 1,000, listed as a **single prize position** (GDG page says "pool") |
| Team | **Max 5**, solo allowed; rules acceptance + Kaggle identity verification required |
| Format | Kaggle **hackathon** (human-judged writeup), notebooks enabled |
| Origin | **Cloned from Google's official "Build with Gemma – Community Hackathon Template"** — so its Overview/Evaluation/Rules text is Google's standard template |
| Field size | Only **~17 entrants** had joined as of July 5 — a small field; a polished submission has a genuinely high win probability |

## 3. How this is judged — and what actually wins

### The rubric (Google's community-hackathon template — high confidence this is Embu's rubric)
| Criterion | Weight | What it means |
|---|---|---|
| **Impact & Vision** | **40** | "How clearly and compellingly does your project address a significant real-world problem?" — assessed mainly *through the video* |
| **Video Pitch & Storytelling** | **30** | "How exciting, engaging, and well-produced is the video? Does it tell a powerful story?" |
| **Technical Depth & Execution** | **30** | "Is the technology real, functional, well-engineered, and **not just faked for the demo**?" |

Since Impact is judged through the video, **the video carries ~70 of 100 points**. This is a
storytelling competition backed by engineering proof — not a leaderboard contest.

### Required submission components (all public, all *submitted* — drafts are not judged)
1. **Video demo ≤3 minutes on YouTube**, attached to the competition Media Gallery.
2. **Kaggle Writeup** — a **cover image is mandatory** (you literally cannot submit without one).
   Its stated purpose: "prove the video demo is backed by real engineering."
3. **Public code repo** (GitHub or public Kaggle notebook), clearly showing the Gemma implementation.
4. **Live demo URL / demo files** judges can try — for TCC: **installable APK on GitHub Releases**
   + a public **Kaggle notebook** running the same Gemma 4 pipeline for judges who won't sideload.
5. One submission per team.

### Evidence from actual winners (Gemma 3n Impact Challenge, 600+ entries, Dec 2025)
- **1st ($50k): Gemma Vision** — **on-device Android app** (MediaPipe + flutter_gemma) for blind
  users, co-designed with the developer's blind brother. Real named beneficiary + fully on-device
  + genuinely working. **TCC deliberately follows this exact winning profile.**
- **2nd: Vite Vere Offline** — offline companion for cognitive disabilities.
- **3rd: 3VA** — AAC tool, **fine-tuned** locally; cited for cost-effective personalization.
- **Ollama prize: LENTERA** — offline education hub on cheap hardware for disconnected regions.
- **African-language benchmark: Sunbird AI** — Gemma 4 E2B fine-tuned for Luganda/Acholi running
  offline on Android, backed by their own dataset. Exactly the packaging to emulate.

### Ranked attributes that predict winning
1. Polished ≤3-min story video: 5-second hook → problem → working product.
2. A **specific, named beneficiary** (a real Embu student, ideally on camera) — not "students".
3. Demonstrably real tech; judges cross-check video vs writeup vs repo.
4. Exploits Gemma's differentiators: **on-device, offline, multimodal, local language** — all four.
5. **Fine-tuning or a novel pipeline** beats prompting-only for Technical Depth.
6. Proof-of-work writeup: architecture, exact Gemma usage, challenges overcome.
7. Some evaluation evidence (even light before/after benchmarks).
8. Deployability **shown on camera** (phone in airplane mode) — not claimed.

### Fatal mistakes (any one can effectively disqualify)
- Private repo, unlisted-broken video, demo behind login → unverifiable → dead.
- Writeup left as **draft** at deadline → explicitly not judged.
- Missing cover image → cannot submit.
- Mocked demo caught by repo cross-check → kills the technical score.
- Prompting-only thin wrapper → fails the organizers' own "cringe AI wrapper" test.

---

## 4. Ground truth: Gemma 4 (corrections to the AI proposals)

Gemma 4 **is real** (announced April 2, 2026, Apache 2.0 — verified on Google's official docs,
blog, and Kaggle). The proposals were right about more than expected, with two corrections:

| Variant | Size (eff/raw) | Context | Modalities | Notes |
|---|---|---|---|---|
| gemma-4-E2B-it | ~2B / 5B | 128K | text+image+video+**audio** | edge tier; .litertlm ≈ 2.6 GB; **TCC's on-device model** |
| gemma-4-E4B-it | ~4B / 8B | 128K | text+image+video+**audio** | edge tier; .litertlm ≈ 3.65 GB — needs 8 GB+ RAM |
| gemma-4-12B-it | 12B | 256K | text+image+video (no audio) | encoder-free multimodal; laptop/dev use |
| gemma-4-26B-A4B-it | 26B MoE (~4B active) | 256K | no audio | strong tool use; free on AI Studio |
| gemma-4-31B-it | 31B | 256K | no audio | LMArena #3 open model (Google claim) |

**Corrections:** audio input is **edge-models-only** (E2B/E4B), and 256K context is
**large-models-only** (edge = 128K). Edge models are also the *weakest* at tool calling — so TCC
keeps its tools few and its schemas simple (see §8).

Other deployment facts that matter:
- **Function calling is native** to Gemma 4 (structured tool calls via constrained decoding);
  works on-device through LiteRT-LM and is exposed directly in Dart by flutter_gemma.
- **Fine-tuning**: Unsloth QLoRA on E2B (~8–10 GB VRAM) or E4B fits a **free Kaggle T4 (16GB)**;
  flutter_gemma can load LoRA weights — a fine-tune is actually *deployable in the app*.
- **Vision/OCR**: strong on printed docs/forms (~91% field accuracy on photographed handwritten
  invoices in community tests); messy handwriting is the weak spot — pre-test every demo image.
- **Swahili**: trained (140+ languages), but **E2B's multilingual quality is the weakest tier** —
  mitigate with tight system prompts and native-speaker review; LoRA if needed.
- **Ollama/llama.cpp** (`gemma4:12b` etc.) remain the laptop dev/eval path; AI Studio hosts
  26B/31B free with an API key as an online reference.

---

## 5. Ground truth: local context (the biggest fixes)

### 🔴 The language correction that could save the whole pitch
One proposal repeatedly claims **Kimeru** is Embu's local language. **Wrong.** Embu County speaks
**Kiembu** (Kīembu; the Aembu people, ~600k speakers). Kimeru is Meru County's language and is
actually the *most distant* related neighbor (~63–65% lexical similarity, vs Kimbeere ~85%,
Kikuyu ~73%). Pitching "Kimeru for Embu" to Embu judges would instantly brand the project as
AI-generated and outsider-made. Getting **Kiembu** right — and saying so on stage — is a moat.

### Language data reality (be honest — judges reward honesty)
- **Kiembu: essentially zero public NLP data.** So don't claim a Kiembu model. Instead:
  **hand-collect a small Kiembu campus phrasebook/dataset with real students** (greetings,
  campus terms, common questions). "We collected our own Kiembu data on campus" is a genuinely
  impressive, unfakeable differentiator.
- **Sheng:** minimal data, fast-shifting. Deliver as prompt-engineered code-switching flavor;
  don't promise fluency.
- **Swahili:** rich resources (KenCorpus, Helsinki Corpus, Common Voice ~700+ hrs, Masakhane).
  This is where a fine-tune is feasible.

### University of Embu — real documents to ground the RAG layer (all live URLs)
- Student Handbook 2024/25 PDF: `departments.embuni.ac.ke/firstyears/images/Student_Hand_book/STUDENT_HANDBOOK_2024_2025.pdf`
- Fee structure: `embuni.ac.ke/fee-structure/` · Hostels: `departments.embuni.ac.ke/accommodation/`
  and booking portal `app.embuni.ac.ke/hostels/public/` · FAQs: `admissions.embuni.ac.ke/index.php/f-a-q-s`
- UoEm: ~8,000–9,000 students, Sept–Aug year, two 16-week semesters + May–Aug trimester.

### Verified student pain points (2025/26 — current, not generic)
- **HELB/HEF is in genuine chaos**: the new funding model was ruled unconstitutional (Dec 2024),
  appeals mechanism ordered (Mar 2025), disbursement delays caused protests, ~450,000 eligible
  students unfunded (allocation Sh41.5B vs Sh74.4B need), portals showing "successful" with no
  money, fees revised Sept 2025 forcing re-applications. **A HELB/fee explainer grounded in
  current official documents hits a raw wound** — but never hard-code fee math; RAG over live docs.
- **M-Pesa tariffs**: public and stable (Safaricom tables). Easy tool, but commoditized — keep it
  as a supporting agent tool, not the headline.
- **Phones**: budget Tecno/Infinix/Itel; 4GB RAM low end, **6GB in the Ksh15–30k band**. This is
  the binding hardware constraint — see §8 for what it means. **Students carry phones, not
  laptops** — which is why TCC is an Android app.
- **Information chaos is real**: fees/deadlines/updates live in fragmented WhatsApp groups.

### Competitive field
Existing players to differentiate from: UlizaLlama (Swahili Llama-2, cloud), SOMANASI/Kytabu
(GPT-4 Swahili tutor, cloud), Simba AI, campus WhatsApp fee bots (a common student-project genre).
Typical GDG-hackathon submissions are **cloud-API chatbot wrappers**. Honest differentiators no
one else will have: offline on-device Gemma 4 + photo-reading of real campus documents +
hand-collected Kiembu layer — all on the device students actually own.

---

## 6. TCC — the identity, and what it inherits from each proposal

**The Campus Collective**: the name *is* the architecture. TCC is not one chatbot — it's a
**collective of specialist agents** (Somo, Karani, Hustle) working for the student, the same way a
campus community shares survival knowledge. Micro-personality: the app acknowledges completed
actions with **"Poa!"** (inherited from the POA proposal — cheap to build, memorable to judges).

### The fusion matrix — best of each proposal, merged into TCC
| Source proposal | Adopted into TCC | Killed (and why) |
|---|---|---|
| **Campus Compass AI** | **Smart Budget & Finance Tracker + AI Budget Maker** (Hustle: tell it your income — HELB disbursement, side hustle — it drafts a semester/monthly budget, then tracks spending against it with weekly insight cards); receipt scan → auto-categorized expense entry (Hustle); **Deadline Guardian → reborn as Ratiba**, the AI day-planner agent (syllabus/handout → deadline extraction → planned day + reminders); **timetable photo → structured weekly schedule** (feeds Ratiba); slides/notes → summaries + flashcards/quiz (Somo) | Roommate matcher & generic recommendations (no data, screams wrapper); PWA/Next.js stack (web target can't do on-device vision/tools; students are phone-first) |
| **Mwanga** | The **agent-collective structure and Swahili names**; eval harness with concrete metrics; QLoRA fine-tune plan; **WhatsApp-shareable outputs** (share sheet on every result); **Hustle copywriter** — WhatsApp Status marketing copy in Sheng for the student's side hustle (pure prompting, cheap, authentic); honesty-about-coverage framing; persona-led video script | Separate FastAPI backend + cloud 12B tier as primary (TCC is on-device-first; laptop 12B demoted to dev/eval) |
| **CampusSync** | **Intent router** — one chat box, model routes to the right agent; **rich result cards** in chat (budget summary card, deadline timeline card) instead of text walls; study-schedule generation folded into **Ratiba**; Opportunity Radar (curated GDG/tech-events feed) as **stretch-only** | Supabase/pgvector cloud RAG (offline-first instead); "premium SaaS dashboard" web UI; Nairobi-generic framing |
| **POA** | Grounded **citations + "sample data" labeling**; **matatu fare estimator** (peak/rain multipliers — authentic detail) as a Hustle tool; **hostel-notice photo → structured listing card** (Karani, same vision pipeline); **emergency/safety contact card** (campus security, GBV/emergency short-codes) in Karani; "Poa!" personality; commit-history-as-evidence; verify-rules-on-day-1 discipline | Its web/PWA delivery; hosted-cloud primary demo path (TCC demos on the physical phone) |

### The four agents (lock scope here — nothing else before freeze)
| Agent | Track hit | What happens in the demo |
|---|---|---|
| **📚 Somo** (study) | Multimodal vision | Photo of handwritten/printed lecture notes or a past paper → summary, 5-question self-quiz, explanation in Sheng-flavored Swahili; share to WhatsApp |
| **📜 Karani** (bureaucracy) | Vision + on-device RAG | Photo of a fee statement / HELB-HEF letter / syllabus / hostel notice → plain-Swahili step-by-step or structured card, **extracted deadlines → handed to Ratiba**, every claim **cited to the UoEm handbook/fee PDF chunk**, "verify with the office" below confidence threshold; safety-contacts card |
| **💸 Hustle** (money agent) | AI agent (native function calling) | **AI Budget Maker**: "Nimepata HELB 15k na side hustle inaniletea ~2k kwa wiki" → drafts a monthly budget → tracks every logged/scanned expense against it → weekly insight card ("umetumia 60% ya food budget, wiki 2 zimebaki"). Plus live tool calls: `mpesa_tariff()`, `ledger()`, `matatu_fare()`; **Hustle copywriter** drafts Sheng WhatsApp-Status ads for the side hustle |
| **🗓️ Ratiba** (day planner) | AI agent (planning + reminders) | "Panga siku yangu" → the model assembles the day from the class timetable (photographed once, parsed to a schedule), Karani's extracted deadlines, and the student's own tasks → prioritized day plan card + local notifications. **MVP is deliberately thin**: local data only, no calendar sync, no recurring-task engine |

Scope note: Ratiba and the Budget Maker are the two features most likely to balloon. Both ship as
*chat-driven plans over local SQLite* — if either threatens the July 14 freeze, they degrade
gracefully (Ratiba → deadline list + reminders; Budget Maker → tracker + weekly summary) rather
than slipping the schedule.

### Language strategy (honest and layered)
1. **English + Swahili + Sheng code-switching** — prompt-engineered with few-shot examples,
   optionally reinforced by a deployable E2B LoRA (§9).
2. **Kiembu layer** — hand-collected phrasebook (~100–300 pairs from real students) in the UI
   greetings and system prompt, framed exactly as what it is: "no public Kiembu data exists, so we
   collected our own."

---

## 7. Why a mobile app (Android first, iOS-ready — the decision, documented)

- **Reach**: students carry their phones everywhere; laptops are rare on Kenyan campuses. ~93% of
  Kenyan phones are smartphones; the target install base is budget Tecno/Infinix/Itel (4–8 GB RAM).
- **Judging fit**: the advanced track is literally "on-device model deployment", and the Gemma 3n
  Impact Challenge **winner was an on-device Android app** built with the same stack TCC will use.
- **Story fit**: "no bundles, no server, works in airplane mode" only lands emotionally when shown
  on the phone a student actually owns.
- **Toolchain is ready**: as of July 2026 the Android path is first-party and current (see §8) —
  this was the riskiest unknown and it checks out.

**Both Android and iOS**: Flutter + flutter_gemma target both platforms, so TCC is built as one
codebase for both from day one. **Android is the hackathon demo/judging platform** (it's what
Kenyan students own, APKs are sideloadable for judges, and our test devices are Android); the iOS
build is kept compiling but is **validated after the hackathon** — iOS demands newer 6 GB+ iPhones
for E2B, and TestFlight review adds days we don't have. Don't spend a single pre-deadline day on
iOS polish.

---

## 8. Android-first architecture (researched 2026-07-05)

### Runtime decision
| Option | Status | Verdict |
|---|---|---|
| **flutter_gemma v1.2.1** (released 2026-07-05) | Gemma 4 E2B/E4B, vision + audio input, **Dart function calling**, on-device RAG add-ons, GPU/NPU | ✅ **Build on this** — every required feature first-party, team knows Flutter; **pin the version** |
| LiteRT-LM (Kotlin) | Current Google-recommended native engine; E2B (2.6 GB) / E4B (3.65 GB) .litertlm; vision+audio; function calling via constrained decoding; MTP drafters up to 2.2× faster | Underlies flutter_gemma; drop to it only if the plugin blocks us |
| MediaPipe LLM Inference API | **Maintenance-only in 2026** — Google says migrate to LiteRT-LM | ❌ Don't start new work on it |
| llama.cpp/MLC/ONNX on Android | No integrated vision+tools+.litertlm path | ❌ Days of glue code for less |
| **google-ai-edge/gallery** (Apache-2, open source) | Ships a camera→multimodal Q&A workspace + function-calling guide | 📖 Read/fork as reference for camera + tool wiring |

### First-run experience (onboarding + in-app model download)
The app opens with a **landing animation → 3 onboarding screens**:
1. **What is TCC** — "a collective of AI agents in your pocket" (Somo/Karani/Hustle in one visual).
2. **Why TCC** — offline, private, kwa lugha yetu; no bundles needed after setup.
3. **Get your AI** — a real **Download button** that pulls the model onto the device via
   flutter_gemma's `ModelFileManager` (`fromNetwork().install()`): progress bar, resume support,
   and an explicit **"~2.6 GB — use campus Wi-Fi"** warning (respecting data bundles *is* the
   brand). When the download completes, the user proceeds into the app and everything runs
   locally and offline from then on.

Rules for this flow: onboarding is skippable on later launches; the model URL is remote-config so
we can swap in the fine-tuned model without an app update; the **precomputed RAG index ships
inside the APK** (corpus is small — embed it at build time, no on-device indexing); and **judged
demos never download live** — demo devices are pre-cached via `adb push` (the download screen is
shown in the video instead, sped up).

### Brand assets & app identity
The logos live in **`app/assets/brand/`** (moved from repo root 2026-07-05) and are the canonical
brand files referenced by the app build:

| File | Role | How it's wired |
|---|---|---|
| `logo_icon.svg` | **App icon** in the phone's app drawer / home screen (Android + iOS) | Launchers need raster icons: export a 1024×1024 PNG from the SVG, then run **`flutter_launcher_icons`** to generate the Android adaptive icon + iOS asset-catalog sets |
| `logo_animated.gif` (1200×1200, ~3.7 MB) | **Animated splash** shown when the app opens | Native splash screens can't play GIFs, so: `flutter_native_splash` shows the static logo for the first frames, then a Flutter splash *widget* plays the GIF (or a Lottie/WebP conversion if the GIF stutters or bloats the APK) before landing on onboarding/home |
| `logo_static.svg` | **In-app logo** on the top bar of every page | Rendered via `flutter_svg` in the shared `AppBar` widget so it appears once, consistently, across all screens |

Rules: these three files are the single source of truth — no resized copies committed elsewhere
(generated icon sets are build artifacts); any logo revision replaces the file here and regenerates.

### App composition
- **Model**: Gemma 4 **E2B int4 (.litertlm, ≈2.6 GB)** — E4B (3.65 GB) is NOT safe on 6 GB phones.
- **RAG**: **EmbeddingGemma (308M) + sqlite-vec** via `flutter_gemma_rag_sqlite` over the UoEm
  corpus. Retrieve top-k small chunks — do NOT prompt-stuff on a phone (time-to-first-token + RAM).
- **Tools** (Dart functions via flutter_gemma; simple flat schemas, because edge models are the
  weakest tool-callers): `mpesa_tariff(amount, txn_type)` · `ledger_add/summary()` (SQLite) ·
  `budget_make/status()` · `matatu_fare(route, peak)` · `task_add(title, due)` ·
  `plan_day(date)` · `set_reminder(date, label)` · `safety_contacts(category)`.
- **Router**: intent classification by the same model (one chat box → right agent persona).
  **Tool-count mitigation**: the router means each agent only ever sees its *own* 2–4 tools per
  request (Hustle gets money tools, Ratiba gets planning tools) — the model never faces all eight
  schemas at once, which keeps edge-model tool calling reliable.
- **Vision hygiene**: downscale/compress photos before inference; one image per turn.
- **Output UX**: stream tokens (feels responsive even at low tok/s); cap answer length; rich cards.

### Performance reality (set expectations now, not on demo day)
- Published fast numbers (~48–52 tok/s E2B) assume flagship GPU/NPU (Snapdragon 8-gen2+,
  Dimensity 9000+, Pixel Tensor).
- Budget MediaTek Helio (typical Tecno/Infinix) often exposes **no usable NPU/OpenCL** → silent
  CPU fallback → **~2–5 tok/s**. Usable for short answers; painful for long ones.
- Plan: **film/demo on the best Android you can borrow** (recent Pixel/Samsung/Dimensity 9000+),
  *verify it also runs* on a budget Tecno/Infinix and show that honestly ("runs on a 6 GB budget
  phone — slower, but fully offline"). Test on the real target device **by July 8** — do not
  discover CPU-fallback speed on July 15.

### Model delivery & judge distribution
- **Never bundle 2.6 GB in the APK.** Small arm64 APK + model download on first run
  (flutter_gemma `fromNetwork().install()` with its ModelFileManager).
- ⚠️ Gemma weights on Hugging Face are **license-gated** — first-run download would demand an HF
  login/token. **Mitigation: mirror the .litertlm on an ungated public URL** (GitHub Release
  asset/bucket), and **pre-cache the model on all demo devices** (`adb push`) before any judged run.
- **Judges**: APK + install guide on GitHub Releases (expect a Play Protect "install anyway" step
  — document it with screenshots) **plus** a public Kaggle notebook demonstrating the same Gemma 4
  pipeline (vision + tool call + RAG) in Python for judges who won't sideload.
- Do **not** demo the web build — flutter_gemma's web target lacks vision and function calling.

---

## 9. Technical plan

### Repo layout
```
the-campus-collective/
├─ app/                    # Flutter app (TCC) — Android first, iOS-ready
│  ├─ lib/agents/          # somo.dart, karani.dart, hustle.dart, ratiba.dart, router.dart
│  ├─ lib/tools/           # mpesa.dart, ledger.dart, budget.dart, matatu.dart, tasks.dart,
│  │                       #   reminders.dart, safety.dart
│  ├─ lib/rag/             # embeddinggemma + sqlite-vec index/retrieve
│  ├─ lib/llm/             # flutter_gemma setup, model manager, prompts/
│  ├─ assets/brand/        # logo_icon.svg · logo_static.svg · logo_animated.gif (see §8)
│  └─ assets/corpus/       # chunked UoEm corpus + kiembu_phrasebook.json (sourced, labeled)
├─ data/                   # raw UoEm PDFs, corpus prep scripts, sample_images/
├─ finetune/               # Unsloth QLoRA notebook (Kaggle-runnable) → E2B LoRA
├─ eval/                   # eval harness + results.md (before/after table)
├─ notebook/               # public Kaggle companion notebook (same pipeline, Python)
├─ submission/             # writeup.md, video script, cover image, rules-verbatim.md
└─ README.md · LICENSE (Apache-2.0)
```

### Fine-tune (go/no-go on July 11) — trained on our own GPU, shipped in the app
We have an **RTX Pro 6000 (96 GB VRAM) on molab.marimo.io** — far more than QLoRA needs, so use it
for both stages:
1. **Data generation (teacher distillation)**: run Gemma 4 26B/31B as the teacher to generate a
   Swahili/Sheng code-switched instruction set (+ form-extraction examples, + tool-call
   transcripts), then human-review a sample with native speakers. This is the same recipe
   Google's 1st-place multilingual Gemma case study used.
2. **Training**: **Unsloth QLoRA on E2B** (comfortable on 96 GB; Kaggle T4 remains the free
   backup) over the curated set.

**The deployment catch the AI proposals missed**: training outputs HF-format weights, but the
phone runs **.litertlm**. Two paths, attempted in this order:
- **Path A — LoRA adapter (preferred)**: ship Google's official E2B `.litertlm` base + our small
  LoRA file (flutter_gemma documents LoRA loading). Small download, low risk.
  **Validate on day 1** that LoRA loading works with the *multimodal* .litertlm model — if it
  doesn't, fall back to Path B.
- **Path B — full conversion**: merge the LoRA → convert with Google's **ai-edge-torch** →
  publish our own `gemma-4-E2B-tcc.litertlm` on Hugging Face. Riskier conversion step, but Gemma 4
  is **Apache 2.0, so our fine-tuned model can be hosted publicly UNGATED** — which also solves
  the gated-download problem for the onboarding flow, and "we published our own fine-tuned Gemma"
  is a strong writeup line.

**Discipline**: the app must work end-to-end on **stock E2B first**; the fine-tuned model swaps in
via the remote-config model URL. Training is an enhancement layer, never the critical path.
Either way, ship the **before/after eval table** (trilingual QA, tool-call success on 30–50
scenarios, form-field extraction on ~20 photographed docs, tok/s on both demo phones) — that
table is the Technical Depth evidence. If base E2B is good enough by July 11, skip the tune and
keep the eval.

### Engineering discipline
- Pin `flutter_gemma: 1.2.2` (+ `flutter_gemma_litertlm` engine package, registered via `FlutterGemma.initialize(inferenceEngines: [LiteRtLmEngine()])` in `main()`) — the plugin moves fast; do not upgrade mid-hackathon. Native LiteRT-LM libs arrive through Dart native-assets build hooks: after changing these deps, `flutter clean` before building or the `.so`s can be silently missing from the APK.
- Verify the exact `gemma-4-E2B-it.litertlm` URL + download flow on day 1.
- Commit steadily to the public repo (evidence of real work), Apache 2.0 from the first commit.
- Label any unverifiable local figures in-app as "sample data".

---

## 10. 12-day roadmap (July 5 → 17)

| Days | Milestone | Done means |
|---|---|---|
| **Jul 5–6** | Setup + verify | Kaggle: join, accept rules, copy all tabs verbatim, ID-verified. Flutter app scaffolded; **flutter_gemma chat with E2B running on a real phone**; model mirror sorted. **Validate the LoRA-on-.litertlm path (Path A) with a dummy adapter; smoke-test molab GPU access.** Recruit up to 4 teammates (video owner, data/Kiembu owner). Borrow the best demo Android available + a budget Tecno/Infinix. |
| **Jul 7–8** | Vision + corpus + onboarding + brand | Camera → image understanding working (Somo summary + Karani extraction). Onboarding screens + model-download flow working end-to-end. **Brand wiring: app icon generated (flutter_launcher_icons), animated-logo splash, static logo in the shared top bar.** UoEm PDFs chunked into the corpus. 6–10 real demo photos collected. Kiembu phrasebook collection starts. **Tested on the budget target device.** |
| **Jul 9–10** | Tools + RAG + languages + data gen | Dart function-calling tools wired (M-Pesa, ledger, **budget maker**, matatu, **tasks/plan-day**, reminders, safety) with per-agent tool scoping; **Ratiba day-plan flow + timetable-photo → schedule**; EmbeddingGemma + sqlite-vec RAG with citations; intent router; Swahili/Sheng prompts reviewed by native speakers. **On molab: teacher-distill the training set with 26B/31B.** |
| **Jul 11** | **Fine-tune go/no-go** | Either QLoRA E2B on molab (deploy via Path A LoRA or Path B conversion → HF), or lock base model + eval-only path. |
| **Jul 12–13** | Eval + polish + early footage | Eval harness run → `results.md`. Rich cards, WhatsApp share, "Poa!" touches. **Film the airplane-mode demo footage now** (backup if later builds regress). APK release pipeline + install guide. |
| **Jul 14–15** | Freeze + assets | Feature freeze. Record + edit the 3-min video. Cover image. Writeup drafted. Kaggle companion notebook runs top-to-bottom. |
| **Jul 16** | Dry run | Video public on YouTube + Media Gallery; writeup complete; repo public; APK installs on a stranger's phone from GitHub Releases; notebook public. |
| **Jul 17 (event day)** | Attend + submit | Participate 9AM–4PM EAT (visibility with organizers), final polish, **submit hours before the 21:00 UTC / midnight EAT deadline**. Confirm status = submitted, not draft. |

---

## 11. The 3-minute video (where the hackathon is won)

Open with a real Embu student (a named beneficiary — ideally a teammate or friend on camera).
**The airplane-mode toggle comes FIRST, not last** — it frames everything that follows.

| Time | Beat |
|---|---|
| 0:00–0:15 | **Hook**: "This is [Name], second-year at University of Embu. Fee deadline Monday, a HELB letter she can't decode, 50 bob of data." She switches her phone to **airplane mode, on camera**. "Everything you're about to see happens with zero internet." |
| 0:15–0:55 | **Karani**: phone camera photographs her actual fee statement → deadline extracted → reminder set, plain-Swahili explanation, **citation to the UoEm fee PDF shown on screen**. |
| 0:55–1:25 | **Somo**: photo of handwritten notes → summary + quiz in Sheng-flavored Swahili → shares the quiz to a class WhatsApp group. |
| 1:25–1:55 | **Hustle**: code-switched question → the model **calls the M-Pesa tool on screen** → answer + budget card. One line: "Gemma 4's native function calling — the model chooses the tool." |
| 1:55–2:30 | **The collective + the phone**: quick montage of all four agents — including **Ratiba planning the day** ("Panga siku yangu") and the **budget card** — on a **budget Tecno/Infinix** ("slower, still fully offline") + the Kiembu greeting: "no dataset for our language existed — so we collected our own, from students here." |
| 2:30–3:00 | **Close**: "The Campus Collective — a collective of agents in your pocket. Offline. Kwa lugha yetu. Built on Gemma 4, open source, Apache 2.0." Repo/APK/notebook links. "Poa." |

Production notes: real campus backdrops, captions throughout (judges may watch muted), no slides
until the close, every claim reproducible from the repo. If a beat allows, flash a 2-second
sped-up shot of the onboarding **"Download your AI (~2.6 GB, once, on Wi-Fi)"** screen — it makes
"the model lives on the phone" visually undeniable.

---

## 12. Writeup outline (the "proof of work")

1. Problem — the three verified pains, with the 2025/26 HELB crisis citations.
2. Solution: The Campus Collective + the named student persona; why an Android app (students'
   phones are the only ubiquitous computer — §7 reasoning).
3. **Why Gemma 4 specifically** — table mapping each feature to a load-bearing capability
   (E2B on-device via LiteRT-LM/flutter_gemma, multimodal vision, native function calling,
   140+ languages, Apache 2.0).
4. Architecture: Flutter + flutter_gemma + EmbeddingGemma/sqlite-vec RAG; the edge-model
   tool-calling constraint and how TCC designed around it (few tools, simple schemas).
5. Data: UoEm corpus sources, the hand-collected Kiembu phrasebook story, licensing.
6. Evaluation: before/after table (QA accuracy, tool-call success %, extraction accuracy, tok/s on
   flagship vs budget phone).
7. Challenges overcome (HF gating → mirror; CPU fallback on Helio → streaming + short outputs).
8. Limitations, honestly (Sheng is prompt-level; Kiembu is a phrasebook, not a model; 6 GB floor;
   budget-phone speed).
9. Links: video, repo, APK release, Kaggle notebook, HF adapter (if fine-tuned).

---

## 13. Risk register

| Risk | Mitigation |
|---|---|
| Rubric differs from template | Verify on Kaggle Day 1; strategy survives — packaging adapts |
| Budget MediaTek = CPU fallback (2–5 tok/s) | E2B only; stream tokens; short outputs; film on the best borrowed device; show budget device honestly; test by Jul 8 |
| RAM ceiling on 6 GB (model + vision + RAG loaded) | E2B only; close background apps; watch OOM; downscale images |
| HF license gating blocks model download | Ungated mirror (GitHub Release asset), or our own Apache-2.0 fine-tuned model hosted ungated on HF; pre-cache on all demo devices via adb |
| LoRA loading fails on multimodal .litertlm (Path A) | Validate with a dummy adapter on day 1; fall back to Path B (ai-edge-torch full conversion) |
| Fine-tune → .litertlm conversion fails (Path B) | Attempt Path A first; if both fail, ship stock E2B + eval table (app is never blocked on training) |
| 2.6 GB download on student data plans | Onboarding shows size + "use campus Wi-Fi" warning; resume support; download once, offline forever |
| flutter_gemma is fast-moving | Pin v1.2.1; no mid-hackathon upgrades; verify model URL day 1 |
| Edge-model tool calling flaky | ≤5 tools, flat JSON schemas; deterministic fallback router (keyword intent → direct tool) if the model's call is malformed |
| Vision misreads a demo photo | Pre-test all demo images repeatedly; keep clean backups |
| Play Protect scares judges off the APK | Install guide with screenshots; Kaggle notebook as the no-install judge path; video as primary evidence |
| Fine-tune eats the schedule | Hard go/no-go July 11; eval table ships either way |
| Swahili/Sheng reads as fake | Native-speaker teammates review every scripted response |
| HELB facts go stale | RAG over live official docs with citations + "verify with the office" gating; never hard-code |
| One-submission mistakes | Jul 16 dry run; submit early Jul 17; confirm not-draft, cover image present, video in Media Gallery |

---

## 14. Where the AI proposals stood (kept vs killed — summary)

- **Right**: the converged shape (offline multimodal + local language + tool-calling agent =
  all three tracks); Gemma 4's existence and most specs; Unsloth/QLoRA feasibility; the
  demo-video-first instinct; "one killer demo, not three half-builds". The fusion matrix in §6
  shows exactly which feature each proposal contributed.
- **Wrong / fixed**: **Kimeru → Kiembu** (fatal-if-shipped error); "audio on all models" (edge
  only); "256K everywhere" (large models only); implied Kiembu/Sheng trained fluency (no data —
  reframed as hand-collected phrasebook + prompt-level code-switch); "runs on any student phone"
  (6 GB floor + budget-chip speed stated honestly); web/PWA delivery (web target lacks vision +
  function calling; students are phone-first → native Android); M-Pesa calculator as headline
  (demoted to supporting tool); hard-coded HELB/fee logic (replaced by cited RAG);
  "$400/$350/$250 split" and several invented rules (unverified — the Kaggle API shows one $1,000
  prize; confirm on Kaggle); 1-day-build framing (12-day runway; use it).

---

## 15. Immediate next actions (today/tomorrow)

1. **Log into Kaggle** → join `build-with-gemma-gdg-embu` → accept rules → verify identity →
   copy Overview/Evaluation/Rules/Data verbatim into `submission/rules-verbatim.md`.
2. Install Flutter toolchain + Android SDK; scaffold the app; add `flutter_gemma: 1.2.2` + `flutter_gemma_litertlm` (pinned);
   confirm the `gemma-4-E2B-it.litertlm` download URL and get chat running on a real phone.
3. Set up the ungated model mirror (GitHub Release asset) + `adb push` pre-cache flow.
4. **Validate the training pipeline early**: smoke-test the molab RTX Pro 6000 (load E2B, run one
   QLoRA step), and test LoRA loading on the multimodal .litertlm in flutter_gemma with a dummy
   adapter — this decides Path A vs Path B while there's still time to react.
5. Download the UoEm handbook + fee structure PDFs (§5 URLs) into `data/`.
6. Recruit teammates (max 5): a native Swahili/Sheng speaker, a Kiembu speaker for the phrasebook,
   someone who can shoot/edit video. Source two demo phones: one strong (Pixel/flagship-class),
   one budget Tecno/Infinix with 6 GB RAM.
7. Photograph the first batch of real demo documents (fee statement, HELB letter, handwritten
   notes, past paper).

---

## 16. Design system & complete page map

> Produced 2026-07-05 by two parallel UX-architecture passes (core journey + data/system/edge),
> merged and reconciled here. This is the build-ready inventory of **every** page, modal, and
> system state in TCC v1.

### 16.1 Design system (dark-only)
**Mandate: pure-black AMOLED, dark mode only for v1** (no theme toggle; tokens kept semantic so a
light theme could be added post-hackathon). Colors derive from the actual logo files
(`app/assets/brand/`): the mark is a purple/teal pinwheel.

| Token | Value | Use |
|---|---|---|
| `bg` | `#000000` | Every screen background (AMOLED black) |
| `surface` / `surface2` | `#0D0D0F` / `#131316` | Cards, sheets, bubbles (elevation steps) |
| `border` | `#1F1F24` | Card/keyline borders |
| `primary` | **`#6706E5`** (logo purple) | Brand, user bubbles, primary emphasis |
| `accent` | **`#1AD8C9`** (logo teal) | CTAs, progress, success, streaming caret, "Poa!" toasts |
| `text` / `textMuted` / `textDisabled` | `#F5F5F7` / `#A0A0A8` / `#5A5A62` | Type hierarchy |
| `danger` / `warning` | `#FF4D4D` / `#F0A500` | Errors, overdue; low-confidence banners |

- **Agent identity tints** (avatar dot + chip on every attributed reply, app-wide): Somo purple
  `#6706E5` · Karani amber `#F0A500` · Hustle green `#2ECC71` · Ratiba teal `#1AD8C9`.
- **Type scale**: 30/24/20/16/14/12; body 16, line-height 1.5.
- **Signature components**: rich result cards (inline in chat, reused in Library), quick-action
  chips, tool-call chips (`🔧 Karani anasoma…` → `✓`), low-confidence amber banner, **"Poa!"**
  teal snackbar on every completed write, static `logo_static.svg` in the top bar of every page,
  animated `logo_animated.gif` on splash, `logo_icon.svg` as the launcher icon.

### 16.2 Navigation model (reconciled decision)
**Bottom nav, 4 tabs**: `💬 Chat` (default, the router) · `💰 Pesa` (Hustle dashboard) ·
`🗓️ Ratiba` (day plan) · `👤 Mimi` (hub: **Library**, **Safety**, **Settings**). Somo and Karani
have **no tabs or hub screens** — they are transactional and live entirely in chat via
quick-action chips and attributed replies (deliberate: halves the surface to build in 12 days).
The top bar (black, static logo left, context title center, `⋯` right) persists across tabs; the
tab bar hides under full-screen camera/quiz flows. A dedicated **language-selector screen was
deliberately rejected** — code-switching is the product thesis (the model mirrors the user); a
tone override lives in Settings.

### 16.3 Complete page inventory (61 items)

#### A · First-run (5)
- **P01 Splash** `/` — pure black, animated logo (~1.8s), wordmark fade-in. Auto-routes: first-run → P02; model present → P06; model missing/incomplete → P05. Never blocks on error.
- **P02 Onboarding 1 · "Meet your campus crew"** — 4 agent dots, H1 + body ("Somo, Karani, Hustle na Ratiba — four AI helpers in one chat. Zote kwa simu yako."), dots 1/3, `Endelea` / `Ruka` (skip → P05).
- **P03 Onboarding 2 · "Why TCC"** — 3 icon rows: 📶 offline/no bundles, 🔒 "Yako ni yako — everything stays on your phone", 🗣️ "Sheng, Kiswahili, English — ongea vile unavyoongea". `Endelea` / `Ruka`.
- **P04–P05 Model Download (Onboarding 3)** — H1 "Get your AI ready", size + storage check ("Space needed: 2.6 GB · You have: 11 GB ✓"), amber Wi-Fi banner "⚠️ Tumia Wi-Fi", progress, `Kwa nini?` expander. **States**: idle (`Pakua sasa (2.6 GB)`) · downloading (`Sitisha`, "1.2/2.6 GB · 46% · ~4 min") · paused (`Endelea kupakua`) · failed (`Jaribu tena`, displays the detailed exception under the warning text for easier debugging, resumes from last byte) · verifying ("Inakamilisha…") · done ("Poa! Your AI iko ready." `Anza` → P06). Resumable across app restarts. **Never cut resume/verify.**
- **P06 Home shell** — AppShell with the 4-tab bottom nav; Chat is tab 0.

#### B · Chat & scanning (8)
- **P07 Chat (router)** — the heart. User bubbles purple/right; agent bubbles surface/left with colored avatar + name; streaming tokens with teal caret; collapsible tool-call chips; **inline result cards**; composer (`＋` attach → Camera/Gallery, field "Uliza chochote…", teal `➤`, stretch 🎤); quick-action chips when empty (`📸 Soma notes` · `📄 Fee statement` · `💰 Tengeneza budget` · `🗓️ Panga siku yangu`). **States**: empty (Kiembu greeting "Wĩ mwega! 👋 …" + chips) · thinking · streaming · inference-error (inline `Jaribu tena`) · low-confidence (append "Sina uhakika 100% — thibitisha na ofisi."). Long-press → Copy/Share.
- **P08 Camera Capture** `/scan/camera?intent=somo|karani|expense|timetable` — full-screen preview, framing guide + intent hint ("Weka karatasi ndani ya mstari"), flash, gallery thumb, teal shutter, intent chip. Permission-not-granted card inline.
- **P09 Photo Review/Confirm** — crop handles, `↻ Rotate`, `Piga tena` (retake), optional caption, `Tuma` (send → chat bubble → agent). Cut-first: fine crop + multi-page → auto-full-frame + rotate.
- **P10 Somo Result** — segmented `Muhtasari · Quiz · Flashcards`; key-point bullets + "Kwa lugha rahisi:" Sheng explainer; `Anza Quiz` / `Ona Flashcards` / `Share`. States: loading ("Somo anasoma notes zako…"), low-content ("piga picha wazi zaidi").
- **P11 Quiz** — "Swali 2/5" + progress, 4 option cards, instant right/wrong + "Kwa nini" line, `Endelea`; results "Umepata 4/5 — Poa! 🎉" + review + `Rudia` / `Share score` / `Rudi kwa chat`.
- **P12 Flashcards** — tap-to-flip, swipe, counter "3/8", end state "Umemaliza! Rudia?". Stretch: known/unknown marking.
- **P13 Karani Doc Decoded** — plain-Swahili summary, structured fields (Balance/Due), steps list, **deadline chip `Weka kwa Ratiba`** (→ Poa! + lands in P22), citations "Chanzo: UoEm Fees Policy 2024, uk. 3" (tap → P14), amber low-confidence banner + `Safety & offices`. States: unreadable ("Picha haiko wazi — piga tena"), no-citation.
- **P14 Citation / RAG Source Viewer** — bottom-sheet modal: source doc name + the retrieved chunk highlighted, "from the official UoEm document" note, `Funga` (close).

#### C · Cards in chat (2)
- **P15 Safety Contacts card** — Dean of Students, Fees office, Security, HELB helpline; `📞 Piga` + `📋 Copy` each; "Ukikwama, ongea na hawa." (full page: P31)
- **P16 Hostel Listing card** — per hostel: name, rent KES/mo, distance, vacancy chip ("Nafasi ipo"/"Imejaa"), `📞 Piga`, source line, `Share`. Unparsed → falls back to P13 text.

#### D · Hustle / Pesa suite (7)
- **P17 Budget Dashboard** `/hustle` — month chip, hero "KSh 8,420 left of 24,000" + ring, category bars w/ spent/budget, weekly insight card, `+ Add expense` / `Scan receipt` / `Make a budget`, `View all transactions`. Empty state → CTA to P18. Over-budget → danger bar.
- **P18 Budget Setup Wizard** (3 steps) — income rows (HELB per-semester auto-monthlyized, allowance, side hustle) → fixed costs → `Generate budget` (on-device; "Cooking your budget…") → editable categories + over-income reconcile banner → `Accept budget` (Poa!). Model-fail → even-split template fallback.
- **P19 Transactions List** — filter chips All/Expense/Income, category + date filters, search, day-grouped rows (icon, title, tag, −red/+teal amount), FAB `+`.
- **P20 Add/Edit Transaction** — amount keypad, Expense/Income toggle, category chip grid (smart-guess from title), title, date, note, optional receipt photo; `Save` (Poa!) / `Delete` (confirm).
- **P21 Receipt Scan Confirm** — thumbnail, editable parsed fields (merchant/date/total/category), amber "Double-check this" on low-confidence, optional line-items; `Save expense` / `Edit` / `Retake` / `Discard`. Parse-fail → P20 prefilled with photo.
- **P22 Insights & History** — month switcher, category donut/bars (custom-painted, no chart lib), vs-last-month delta chips, AI insight cards, top merchants. Empty (<7 days): "Not enough data yet."
- **P23 Copywriter Output** — prompt recap chip, generated Sheng ad in WhatsApp-Status-styled preview, tone chips (`Poa/chill` / `Hype` / `Formal`) regenerate, variants dots; `Copy text` / `Share to WhatsApp` / `Edit`.

#### E · Ratiba / planner suite (8)
- **P24 Today / Day Plan** `/ratiba` — date + greeting (Kiembu if enabled), AI day-plan card ("Poa day ahead: 2 classes, 1 deadline, 3 tasks"), vertical timeline (class blocks, deadline pills, checkable tasks → Poa! + strike), `Generate day plan`, quick-add FAB, free-slot hints.
- **P25 Week View** — vertical accordion Mon–Sun, class blocks + deadline markers + task badges, Day/Week toggle. **Cut-first if timeline slips** (P24 + P29 cover 90%).
- **P26 Task List** — chips All/Today/Upcoming/Done, due-date sections, priority dots, swipe complete/delete, FAB.
- **P27 Add/Edit Task** — title, due date+time, priority, notes, reminder toggle + lead time ("1 hr before / morning of"), optional link-to-deadline; `Save` (Poa!) / `Delete`. Reminder toggle fires notif primer (P52) if ungranted.
- **P28 Deadline List** — nearest-first, source badges ("From HELB letter" / "Manual" / "Timetable"), countdown chips (red <48h), link to source scan (→ P34), overdue pinned in danger, FAB manual add.
- **P29 Timetable View** — weekday tabs, class cards (unit, time, venue, lecturer, per-unit color), `Import timetable` (→ P30) / `+ Add class` / long-press edit.
- **P30 Timetable Import Confirm** — source photo, parsed classes grouped by day (all rows editable), amber low-confidence cells, overlap-conflict warnings; `Looks right — Save` (Poa! → P29) / `Add missing class` / `Retake` / `Discard`.
- **P31 Reminder Detail / Snooze** — from notification tap: title, context, countdown; `Mark done` (Poa!) / `Snooze` (10 min · 1 hr · evening · tomorrow) / `Open task` / `Dismiss`. Stale → "Already handled ✓".

#### F · Mimi tab: Library, Safety, Settings (13)
- **P32 Mimi hub** — simple grouped list: Library (→P33), Study sets (→P35), Safety contacts (→P36), Settings (→P37). Local-only display name optional.
- **P33 Documents Library** — segmented All · Notes · Docs · Receipts · Timetables, search, cards (type icon, title, date, agent tint), long-press rename/delete/share. Empty: "Your scans will live here. Everything stays on your phone."
- **P34 Scan Detail** — editable title, original photo (tap fullscreen), per-type result body (reuses P10/P13/P21 widgets), `Re-run` / `Share` / `Add deadline/task` / `Delete`. Missing photo → text-only + note.
- **P35 Saved Quizzes/Flashcards** — tabs Quizzes|Flashcards, cards w/ topic, count, last score / mastery %, `Practice` (→ P11/P12 players), rename/delete.
- **P36 Safety Contacts (full page)** — Campus section (Security/Gate, Clinic, Dean, Warden) + National (Police 999/112, Ambulance, GBV 1195, Childline 116, DCI cybercrime, Red Cross); each `Call`/`SMS`/`Copy`; banner "In danger? Call now — no internet needed."; numbers in bundled JSON asset; footer "verify locally".
- **P37 Settings root** — rows → P38–P44; AI Model row shows live model + storage subtitle.
- **P38 Language & Greetings** — radio EN / Kiswahili / Sheng flavor (drives AI tone + microcopy), toggle **Kiembu greetings** ("Wĩ mwega" style), live sample preview, applies instantly.
- **P39 AI Model Management** — card: "Gemma 4 E2B · 2.6 GB · Ready/Downloading/Missing/Corrupted", storage bar; `Re-download` / `Delete model` (danger confirm) / `Switch model` (advanced sheet: presets + custom URL for the fine-tuned model) / toggles `Wi-Fi only`, `Auto updates`; update banner (→ P57). Reuses the P05 download component.
- **P40 Notifications Settings** — master toggle (links OS settings if denied), per-type toggles (class, deadline, task, budget alerts, morning day-plan), default lead time, quiet hours.
- **P41 Data & Privacy** — hero "Everything stays on your phone… the AI runs locally."; `Export my data` (JSON/zip → share), `Clear chat history`, `Clear all data` (typed confirm; keeps the model), storage breakdown (chats/scans/model).
- **P42 About** — logo, version/build, "Built by [Team] for GDG Embu Hackathon 2026", `Open-source licenses`, model-card note, repo link, Apache 2.0 statement.
- **P43 Help & FAQ** — offline accordion: getting started, "why is the first answer slow?", download/storage, privacy, per-agent guides, "AI got it wrong?" verify guidance; footer → P44.
- **P44 Report a Problem** — category, description, optional screenshot, device-info toggle w/ disclosure; online `Send`, offline `Copy report`/save draft; "Asante! Report noted."

#### G · System, gates & edge states (17)
- **P45 No-Model Gate** — "TCC needs its AI brain first." + storage line; `Download now` / `Wi-Fi only` / `Later` (→ P61 limited mode). Entry: any AI feature without model.
- **P46 Model Corrupted** — "The AI model looks damaged… Re-download to fix (~2.6 GB)"; `Re-download` / `Delete & free space` / `Report problem`.
- **P47 Insufficient Storage** — "You need ~3 GB free; you have 1.2 GB"; `Open phone storage settings` / `Retry` / `Delete old scans` (→ P33); live recheck on return.
- **P48 Low-RAM / Unsupported Device** — soft warn (6 GB+ recommended, `Continue anyway`) vs hard block (<4 GB → limited mode only); shown once, noted in Settings.
- **P49 Camera Permission Primer** (sheet) — "Scan notes, receipts & letters… Photos stay on your phone."; `Allow camera` / `Not now`.
- **P50 Camera Denied** (sheet) — `Open settings` / `Choose from gallery` / `Cancel`; permanently-denied variant.
- **P51 Notifications Primer** (sheet) — "Never miss a class or deadline."; `Turn on reminders` / `Maybe later`.
- **P52 Notifications Denied** (sheet) — `Open settings` / `Not now`.
- **P53 First-Message AI Disclaimer** (modal) — "TCC's AI can make mistakes. Always verify official info (fees, HELB, deadlines) with the real office." + "Got it, don't show again."
- **P54 Low-Confidence Banner** (component) — amber strip on sensitive outputs: "⚠ Double-check this with the office — I might be wrong." + `Why?` / `Find contacts` (→P36) / `See citation` (→P14). Driven by shared `confidence` + `topicSensitive` flags on every AI message/result.
- **P55 Model Warm-up Overlay** — purple-teal pulse, "Waking up the AI… first answer after opening is slower."; auto-dismiss on first token; timeout → `Keep waiting`/`Cancel`.
- **P56 Inference-Failed Inline State** — chat bubble "Couldn't finish that — try again" + `Retry` (OOM on low-RAM devices is expected; never blank-fail).
- **P57 Update-Available Prompt** (sheet) — app-update vs model-update (~2.6 GB, Wi-Fi note) variants; optional vs required (blocking).
- **P58 Offline-Is-Fine Banner** (component) — slim reassure strip: "You're offline — that's fine, the AI works on your phone. ✔"; only share/update/report show "needs internet" notes.
- **P59 Share Fallback** (modal) — "Couldn't open WhatsApp… `Copy text` / `Share another way` / `Cancel`."
- **P60 Notification Deep-Link Router** (spec) — class → P24 · deadline/task → P31 · budget alert → P17 (category highlighted) · daily plan → P24 · download complete → P07 · update → P57; cold-start intents queue until splash + model gate resolve.
- **P61 Limited/Degraded Home** — model absent/declined: Safety, Settings, manual budget + tasks still work; AI cards show "Download AI to unlock." Prevents dead-ends.
- **P62 Global Error / Crash Recovery** — "Something went wrong. Your data is safe on your phone." `Restart` / `Report`.

### 16.4 Shared contracts (build once, reuse everywhere)
- `ScanResult {id, type, sourcePhotoPath, parsedFields, generatedOutput, confidence, topicSensitive, extractedDeadlines[], createdAt}` — produced by the chat scan pipeline, consumed by Library (P34), receipt confirm (P21), timetable confirm (P30).
- `Deadline {title, dueAt, sourceType, sourceScanId}` — produced by Karani (P13), consumed by Ratiba (P24/P28/P31).
- Result-rendering widgets (summary/quiz/flashcards/decoded-steps/receipt-fields) live in one shared `results/` package — used inline in chat AND in Library.
- The P05 download component is embedded by P39, P45, P46, P57.

### 16.5 Cut-first ranking (if the 12 days compress)
1. Voice input 🎤 → drop. 2. Week view (P25) → fold into Today. 3. Image-render share → text-only.
4. Insights charts (P22) → single weekly text insight on P17. 5. Copywriter tone variants → one +
regenerate. 6. Multi-page scan/fine crop → full-frame + rotate. 7. Animated tool chips → static.
8. Lottie splash → static logo fade. 9. Full license list → repo link.
**Never cut**: P05 resume/verify · agent attribution · inline result cards · P54 low-confidence +
verify-with-office · camera→review→confirm · P45–P48 gates · P55 warm-up · P56 inference-retry ·
P36 Safety · P39/P41.

---

## 17. Backend architecture (Supabase)

> Implemented 2026-07-05 on the Supabase project **"The Campus Collective"**
> (`dhobuspndffvhemwcdnl`, region eu-west-1). Migration:
> `supabase/migrations/20260705180000_tcc_core.sql`.

### 17.1 Philosophy — the backend never sees user data
TCC is offline-first and privacy-first. The phone is the database: notes, scans,
budgets, tasks, chats, and every AI inference live in on-device SQLite (Drift) and
never leave the device. The backend exists only to **ship things DOWN** (the model
manifest and refreshable content packs) and accept **anonymous feedback UP**. This
is what lets the privacy screen (P41) honestly say "everything stays on your phone",
and it means the app is fully functional with the backend unreachable.

### 17.2 Schema (4 tables, all RLS-guarded)
| Table | Purpose | Anon access |
|---|---|---|
| `model_manifest` | Remote config for the on-device model: `variant` (e2b-base / e2b-tcc fine-tuned), `version`, ungated `url`, `size_bytes`, `sha256`, `min_app_version`, `channel`, `is_active`. Lets us swap in the fine-tuned model without an app update. | read active rows |
| `content_packs` | Versioned offline content the app refreshes when online: `kind` ∈ {corpus, safety_contacts, mpesa_tariffs, matatu_fares, kiembu_phrasebook, faq}, `version`, `storage_path`, `sha256`. | read active rows |
| `feedback_reports` | P44 "Report a problem" — anonymous, **insert-only** (write-only mailbox; no read policy). Optional `device_info` jsonb only if the user opts in. | insert only |
| `campus_events` | Opportunity Radar feed (stretch) — curated events. | read active rows |

### 17.3 RLS posture
Anon/publishable key can **only**: `select` active rows of the three distribution
tables, and `insert` into `feedback_reports`. No update/delete/select on feedback;
no write to distribution tables (those are seeded by us via the service role).
Storage: a public `content` bucket holds the small JSON content packs (read-only to
anon).

### 17.4 Model hosting decision
The 2.6 GB model binary is **not** stored in Supabase (free-tier storage + egress
limits, and egress would be costly). `model_manifest.url` points at an **ungated
public mirror** (our Hugging Face repo — Gemma 4 is Apache 2.0, so we can host our
own fine-tuned `.litertlm` ungated, which also removes the HF-login friction from
first-run download). Supabase only serves the tiny manifest row that names the URL,
size, and checksum.

### 17.5 App ↔ backend flow
1. **First run**: app reads `model_manifest` (active, channel=stable) for the model
   URL + checksum; downloads via `background_downloader` (resume + sha256 verify);
   falls back to the compiled-in `Config.defaultModelUrl` if offline.
2. **On launch when online**: refresh `content_packs`; if a newer `version` exists,
   download the JSON into app storage; otherwise use the copies bundled in the APK
   (`assets/content/`). The bundled copies guarantee full offline function.
3. **Feedback**: P44 inserts one row into `feedback_reports`; on failure/offline it
   falls back to clipboard copy (never lost, never blocking).

### 17.6 Keys & config
The app embeds only the **publishable/anon** key (`Config.supabaseAnonKey`) — safe
to ship, gated by RLS. The service-role key is never in the app. Seed data
(`data/content/*.json`) doubles as both the Supabase content-pack payloads and the
APK's bundled offline assets, so the two never drift.

### 17.7 Status / follow-ups
- Migration authored and ready; **push requires the DB password or a personal
  access token** (only the owner has these — the CLI keychain read triggers a GUI
  approval). Apply with `supabase db push` (enter DB password) or run the migration
  SQL in the Supabase dashboard SQL editor. The app runs fully without this — the
  backend is an enhancement layer.
- After push: seed `model_manifest` with the real HF `.litertlm` URL + sha256, and
  upload `data/content/*.json` to the `content` bucket + insert `content_packs` rows.

---

## 18. Gemma fine-tuning plan (molab RTX Pro 6000 → on-device)

> Hardware: RTX Pro 6000 (96 GB VRAM) on molab.marimo.io. Goal: a TCC-specialized
> Gemma that (a) code-switches English/Swahili/Sheng naturally, (b) reads campus
> documents into structured JSON, (c) reliably calls the app's tools — then ships
> **inside the Android app**.

### 18.1 Which model to fine-tune — decision
**Fine-tune `gemma-4-E4B-it`, deploy `E2B` or `E4B` on device.** Reasoning:
- The app must run **on-device on a 6 GB budget phone**, which caps us at the edge
  tier (E2B ~2.6 GB / E4B ~3.65 GB .litertlm). The 12B/26B/31B models can't run on
  the target hardware, so they are out for the shipped model (they're only useful
  as *teachers* — see below).
- Among edge models, **E4B has clearly better multilingual quality** than E2B
  (the weak spot for Swahili/Sheng), and it still QLoRA-fine-tunes comfortably —
  the 96 GB RTX Pro 6000 is far more than the ~10–16 GB QLoRA needs.
- **Ship decision by device**: default the app to **E4B** on 8 GB+ phones (best
  quality) and **E2B** on 6 GB phones (safety margin). Same LoRA/adapter recipe
  applies to both; the model_manifest (Supabase §17) picks the variant per device.
- Do NOT fine-tune E2B as the primary — train E4B, and if the E2B on-device build
  needs the adapter too, run the same QLoRA on E2B as a second, cheap job.

### 18.2 Three things the fine-tune must teach (the adapters)
1. **Trilingual instruction-following** — English↔Swahili↔Sheng code-switch in the
   register Kenyan students actually use; keep answers concise and practical.
2. **Structured document extraction** — photo/text of a fee statement / HELB letter
   / timetable / receipt → strict JSON matching the app's `ScanResult` schema
   (fields, steps, deadlines, citations, confidence).
3. **Tool-calling format** — emit the app's function calls (`mpesa_tariff`,
   `ledger_add`, `budget_make`, `matatu_fare`, `task_add`, `plan_day`,
   `set_reminder`, `safety_contacts`) with correct flat-JSON args, per-agent scoped.

### 18.3 Data strategy (teacher distillation — the molab GPU earns its keep twice)
No public Kiembu/Sheng instruction set exists, so **generate our own**:
1. On molab, load **Gemma 4 26B/31B** (fits easily in 96 GB) as the **teacher**.
2. Generate ~3–8k instruction↔response pairs across the three skills above, seeded
   from: the UoEm corpus (§5 PDFs), real photographed demo docs, the M-Pesa tariff
   table, and Sheng/Swahili prompt seeds. This mirrors Google's own 1st-place
   multilingual-Gemma recipe.
3. **Human-review a sample** with native Swahili/Sheng speakers; hand-collect the
   **Kiembu greeting/phrasebook** pairs on campus (the honest, unfakeable moat).
4. Hold out ~10% as an eval set for the before/after table (§9).

### 18.4 Training recipe (Unsloth QLoRA)
- Unsloth + `gemma-4-E4B-it`, 4-bit QLoRA, LoRA r=16 (α=16/32), target attention +
  MLP projections, 2–3 epochs, bf16, packing on. On 96 GB you can push batch size /
  sequence length well past the free-tier limits — but keep the adapter small.
- Save the LoRA adapter; also produce a merged fp16 checkpoint for conversion.
- Publish the adapter + merged model to **our own Hugging Face repo** (Gemma 4 is
  Apache-2.0 → host **ungated**, which also fixes the first-run download friction).

### 18.5 Getting it onto the phone (verified recipe, July 2026)
Training outputs Hugging Face weights; the app runs **`.litertlm`**. The **real,
documented tool is `litert-torch`** (Google AI Edge) — NOT the older `ai-edge-torch`
example scripts. Confirmed against Google's official convert-and-run tutorial + a
Gemma-4-on-Android walkthrough. Merge the LoRA into the base (Unsloth
`save_pretrained_merged` / `push_to_hub_merged` — a plain `save_pretrained` produces a
broken artifact on Gemma 4), then:
```
uvx --from litert-torch-nightly litert-torch export_hf \
  --model=<user>/gemma-4-tcc-e4b --output_dir=out \
  --externalize_embedder \
  --quantization_recipe dynamic_wi8_afp32 \
  --vision_encoder_quantization_recipe "" \
  --task image_text_to_text
```
→ `model.litertlm` (~3–4 GB) → upload ungated to HF → point `model_manifest.url` at
it. Runnable via `gemma_model/molab/tcc_convert.py`. **Known risk:** for a multimodal
E4B model the exporter can be imperfect outside the LoRA-trained layers (may need
byte-splicing the tokenizer/metadata from the base bundle). Do NOT pass
`--experimental_lightweight_conversion` (it breaks GPU delegation). If the phone can't
load the result, use the fallback below.
- **Separate-LoRA on `.litertlm` is NOT a public API yet** (open feature request on
  `google-ai-edge/LiteRT-LM`) — so the merge-then-convert path above is the only route.
- Either way the app is **never blocked on training**: it ships on the stock model
  first (the current build already does), and the fine-tuned model swaps in purely
  via the remote-config `model_manifest` URL — no app update, no code change.

### 18.6 Evaluation (the Technical-Depth evidence)
Run on the held-out set, base vs fine-tuned, and put the table in the writeup:
trilingual QA accuracy · form-field extraction F1 (~20 photographed docs) ·
tool-call success rate (30–50 scenarios) · on-device tokens/sec (E2B & E4B on a
flagship and a 6 GB budget phone). Even modest deltas beat empty claims.

### 18.7 Go/No-Go
Fine-tuning is an **enhancement**, decided at the §10 July-11 checkpoint. If base
E4B is already good enough or time is short, ship stock + the eval table. The molab
GPU makes the full recipe feasible in a day, so it's worth attempting — but never at
the cost of a working, submitted app.

### 18.8 The pipeline is built — `gemma_model/`
A complete, runnable pipeline lives in `gemma_model/` (verified against the real
July-2026 HF model landscape: `google/gemma-4-E4B-it`, `unsloth/gemma-4-E4B-it`,
`litert-community/gemma-4-E4B-it-litert-lm` all exist with day-one Unsloth + LiteRT):
`README.md` (which model + why, data sources, the hard conversion step, de-risking) ·
`config.yaml` · `scripts/1_generate_data.py` (programmatic tool-call + doc-extraction
pairs + public Swahili SFT [Aya, Inkuba-instruct] + optional teacher distillation) ·
`2_train_qlora.py` (Unsloth QLoRA on E4B) · `3_merge_and_push.py` (merge + push to HF)
· `5_eval.py` (base vs tuned → `out/results.md`) · `notebooks/marimo_train.py`
(molab-native). **Simplest path actually used:** `molab/tcc_train.py` (one self-
contained file — data + train + merge + push) and `molab/tcc_convert.py` (the verified
`litert-torch export_hf` on-device conversion, §18.5). The deterministic data
generation was run and verified locally; only the GPU steps need molab.

### 18.9 Wiring the trained model into the app
The app depends only on the `GemmaService` interface. The real on-device engine is
written and ready at `app/lib/llm/flutter_gemma_service.dart.template`. Kept as
`.template` so the app keeps building on the stub until validated on a physical 8 GB+
Android. Once the on-device `.litertlm` is on HF, the Supabase `model_manifest.url`
(§17) swaps it in with **no app update**.

### 18.10 Current status (2026-07-07)
- ✅ **Fine-tune trained and live on HF**: `Eugeniuss/gemma-4-tcc-e4b` (merged) +
  `Eugeniuss/gemma-4-tcc-e4b-lora` (adapter). Trained on the molab RTX Pro 6000 via
  `gemma_model/molab/tcc_train.py`; loss 1.79 → 0.57 over 380 steps on ~3.3k examples.
- ✅ **App pointed at the fine-tune**: `Config.defaultModelUrl` →
  `Eugeniuss/gemma-4-tcc-e4b-litertlm` (the on-device build); stock E2B kept as
  `fallbackModelUrl`. App still analyzes clean and builds.
- ⏳ **On-device conversion**: run `gemma_model/molab/tcc_convert.py` (the verified
  `litert-torch export_hf` recipe, §18.5) to produce + upload the `.litertlm`.
- ⏳ **Engine activation blocked on a toolchain bump**: `flutter_gemma 1.2.2` (the
  template's API) needs **Dart ≥ 3.12**; this repo ships Flutter 3.41 / Dart 3.11.5.
  Run `flutter upgrade` first, then follow the activation steps in the template
  header. (Or use `flutter_gemma ^0.10.2` on the current toolchain — older API.)

---

## 19. Build status & instructions (2026-07-06)

**The app compiles, analyzes clean, and builds a release APK.** ~11.5k lines of
Dart across 41 files; release APK 30.8 MB (arm64).

### Current state
- ✅ `flutter analyze` → No issues found (all 41 files).
- ✅ `flutter build apk --debug` and `--release` (arm64) succeed.
- ✅ Full first-run flow → 4-tab shell → all four agent suites → Mimi/Settings, all
  navigable and functional against the offline stub LLM + local SQLite.
- ✅ Language: English default, switch to Kiswahili/Sheng in Settings, **persisted**
  across restarts; strings resolve through `lib/core/l10n.dart` + inline switches
  (English default everywhere).
- ⏳ On-device Gemma: the app runs on `StubGemmaService` (deterministic offline demo
  responses) so it builds and demos end-to-end today. Swap to the real
  `flutter_gemma` engine behind the same `GemmaService` interface once validated on
  a device (roadmap day-1 task) — no UI changes needed.
- ⏳ Backend migration: authored, needs `supabase db push` with the DB password.

### Build commands
```bash
cd app
flutter pub get
dart run build_runner build          # regenerate drift (database.g.dart) if schema changes
dart run flutter_launcher_icons      # regenerate app icon from assets/brand/
flutter analyze
flutter build apk --release --target-platform android-arm64
# output: build/app/outputs/flutter-apk/app-release.apk
# install on a device: adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Architecture map (lib/)
- `theme/` — TCC tokens + dark-only Material 3 theme.
- `ui/widgets.dart` — shared premium kit (TccScaffold, TccCard, TccChip, AgentAvatar,
  EmptyState, LowConfidenceBanner, poa, SectionHeader).
- `core/` — config (Supabase keys), app_state (providers: db, gemma, lang, flags),
  l10n (string catalog).
- `data/` — drift database, content_service (bundled packs), model_download.
- `llm/gemma_service.dart` — GemmaService interface + StubGemmaService (swap point).
- `features/<suite>/` — onboarding, shell, chat, somo, karani, hustle, ratiba, mimi,
  settings. Routed in `app_router.dart` (go_router), all 30+ routes.

### Remaining to reach the demo (not blockers to the build)
1. Validate `flutter_gemma` + Gemma 4 E2B `.litertlm` on a real 6 GB+ Android; wire
   `FlutterGemmaService` behind the interface.
2. `supabase db push` + seed manifest/content (§17).
3. Fine-tune per §18 (optional, go/no-go July 11).
4. Real Kiembu phrasebook + Swahili tone review by native speakers.
5. Demo video (§11), Kaggle writeup (§12), cover image.
