# TCC demo video — recording script (target 3:00)

## 3-Sentence Pitch

**Problem:** African university students are priced out of AI — cloud tools need expensive data bundles, don't understand their languages, and can't be trusted with personal documents. **Solution:** The Campus Collective is a fully offline Android app that runs Gemma 4 on-device with four specialist agents that scan documents, budget money, study notes, and plan your day — in English, Kiswahili, Sheng, and Kiembu. **Uniqueness:** No servers, no subscriptions, no data leaving the phone — just a fine-tuned model trained on real campus documents, working for students who need it most, at zero cost.

---

One continuous story: **hook → who I am → install it yourself → everything offline → how it's built → close.**

## Before you press record — staging checklist

- **Two phone states.** Record the *install + model download* shot first on a clean install (screen-record separately; speed it up 8–16×). Do the *feature demo* on the phone where the model is already downloaded — never make judges wait on 2.6 GB.
- **Airplane mode ON for the entire feature demo** — the ✈ icon in the status bar is your proof shot. Point at it.
- Pre-load real-looking data so nothing is empty: 3–4 timetable classes for **today**, 2 open tasks, 1 deadline (e.g. "HELB appeal — 15 Jul"), one accepted budget, a few transactions.
- Props: one **printed fee statement** and one page of **handwritten notes**.
- Language set to **English** at the start (you switch to Kiswahili live).
- Practice the voice line once so the mic demo lands first take. First transcription after app start loads the audio tower — warm it up off-camera.
- Clear chat history (Settings) so the routing demo starts clean.

---

## The script

*(SAY = read aloud · SHOW = what's on screen)*

### 0:00–0:12 · HOOK — before your name

**SHOW:** Phone in hand, status bar visible: **airplane mode on**. Hold it to camera.

**SAY:**
> "This phone has no internet. No bundles, no Wi-Fi — airplane mode. And in the next three minutes it's going to read a fee statement, budget my money, quiz me on my notes, and plan my day — in English, Kiswahili na Sheng. And nothing — nothing — leaves this phone."

### 0:12–0:20 · NAME + ONE-LINER

**SHOW:** Cut to the GitHub repo page (screen recording starts).

**SAY:**
> "I'm Eugene Mutembei from the University of Embu, and this is **The Campus Collective** — a collective of AI agents in every student's pocket, powered by Gemma 4 running entirely on-device."

### 0:20–0:45 · INSTALL IT YOURSELF

**SHOW:** Scroll README → tap the APK link → install (8× speed) → onboarding → "Get your AI ready" download (sped up, progress ring visibly moving) → "Success!" → flick airplane mode ON, hold the icon in frame.

**SAY:**
> "Everything is public — you can do this right now. One small APK from the README, then TCC downloads its brain once: Gemma 4, about two-point-six gigabytes, on campus Wi-Fi. It auto-resumes when the network drops — this is Kenya, networks drop. Download once… offline forever. So: airplane mode goes ON now, and it stays on."

### 0:45–1:05 · ONE CHAT, FOUR AGENTS + VOICE

**SHOW:** Chat tab. Type *"I need to budget 5k this week"* → Hustle replies in **formatted markdown**. Tap the **mic**, say: *"Nisaidie kupanga siku yangu kesho"* → transcription appears in the field → send.

**SAY:**
> "One chat box, four specialists. Ask about money — it routes itself to Hustle, the finance agent. And you don't have to type: tap the mic and just speak. That transcription happened **on this phone** — Gemma's own audio model, fully offline. One model doing text, vision, and speech."

### 1:05–1:20 · SPEAK OUR LANGUAGE

**SHOW:** Settings → Language → **Kiswahili**. Back in chat, ask anything → reply arrives in Kiswahili.

**SAY:**
> "English by default. Switch to Kiswahili or Sheng, and every agent follows — it speaks the way students actually speak. We even hand-collected a Kiembu phrasebook — Embu's own language — because no dataset existed. So we started one."

### 1:20–1:45 · SOMO — NOTES BECOME A QUIZ

**SHOW:** Chat → 📸 Scan notes → photograph the handwritten page → summary → open the **quiz**, answer one question → flip a **flashcard**.

**SAY:**
> "Exam season. Photograph your handwritten notes — Somo reads them with on-device vision and turns them into a summary, a quiz, and flashcards. A study group in your pocket, at 2 a.m., costing zero bundles."

### 1:45–2:10 · KARANI — THE BUREAUCRACY KILLER

**SHOW:** Scan the printed fee statement → structured fields (balance, due date) → extracted **deadline → Add to schedule** → point at the **"verify with the office" low-confidence banner**.

**SAY:**
> "This is the one that saves semesters. Fee statement, HELB letter — Karani reads it, pulls the balance and the due date, and hands the deadline straight to my planner. And notice this banner: we engineered against hallucination. The AI only reports what's actually on the document, flags anything sensitive, and always points you back to the office. Trust is a feature."

### 2:10–2:30 · RATIBA + HUSTLE — PLAN THE DAY, PLAN THE MONEY

**SHOW:** Schedule tab → **Generate day plan** → the plan lists the *staged real* classes/tasks/deadline. Quick cuts: budget wizard → **Add income source** ("Chama") → generated budget → copywriter writes a side-hustle ad.

**SAY:**
> "Ratiba plans my day from my *real* timetable and deadlines — grounded in my data, not imagination. Hustle builds a budget around HELB and M-Pesa reality — with my own income sources, because every hustle is different — and even writes my WhatsApp ad for the side business."

### 2:30–2:45 · HOW IT'S BUILT (still airplane mode)

**SHOW:** Chat history sheet (previous conversations, new chat) → cut to README fine-tune section / Hugging Face model page.

**SAY:**
> "Every conversation is saved on this device — private by architecture, not by promise. And we didn't stop at stock Gemma: we trained and fine-tuned Gemma 4 E4B on an NVIDIA RTX PRO 6000 Blackwell GPU — nearly four thousand examples we built ourselves from real campus documents, real M-Pesa tariffs, distilled trilingual conversations, and our hand-collected Kiembu data. Published open, Apache 2.0, ungated."

### 2:45–3:00 · CLOSE

**SHOW:** Back to the phone: airplane-mode icon → app home. End card: repo URL + "Download once. Use offline forever."

**SAY:**
> "No servers. No subscriptions. No data leaving the phone. Just Gemma 4, working for the students who need it most — kwa lugha yetu. The Campus Collective. Download once, use offline forever. **Poa.**"

---

## Cut-for-time priority (if you run over 3:00)

Cut in this order: copywriter ad → flashcard flip → budget custom income → chat history sheet. **Never cut:** the hook, voice transcription, Karani scan + anti-hallucination banner, airplane-mode proof, the fine-tune credit, the close.
