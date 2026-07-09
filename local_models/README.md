# Model Deck — Local Models & Custom Weights Integration

A complete local-AI setup for this project:

- **`ui/index.html`** — a zero-dependency web control panel (Model Deck) that plugs into
  **your models and local models**: Ollama, LM Studio, llama.cpp server, vLLM, or any
  OpenAI-compatible endpoint (including your own hosted API).
- **`modelfiles/`** — 9 custom model definitions: **Alus, Ropus, and Potus**, each in
  **3 versions (v1–v3)** with heavily tweaked generation parameters and personalities.
- **`build_all_models.sh`** — one command to build every model, from a stock base model
  **or from your own weight files (`.gguf`)**.

---

## 1. Quick start

```bash
# 1) Install & start Ollama (https://ollama.com), then pull a base model:
ollama pull llama3.2

# 2) Build the whole fleet — alus/ropus/potus, all versions:
cd local_models
./build_all_models.sh

# 3) Open the UI (serve it over http so the browser can reach Ollama):
cd ui && python3 -m http.server 8090
# then open http://localhost:8090
```

Click **Connect** (defaults to `http://localhost:11434`), pick a model, chat.

> If the browser can't reach Ollama due to CORS, restart it with
> `OLLAMA_ORIGINS="*" ollama serve`.

## 2. Plug in YOUR models

| What you have | How to plug it in |
|---|---|
| Ollama models | Default — just Connect. |
| LM Studio | Switch backend to *OpenAI-compatible*, URL `http://localhost:1234`. |
| llama.cpp server | *OpenAI-compatible*, URL `http://localhost:8080`. |
| vLLM / your hosted API | *OpenAI-compatible*, its URL + API key. |
| **Raw weight files (`.gguf`)** | `./build_all_models.sh --weights /path/to/weights.gguf` — builds all 9 tuned models directly on top of your weights. |

## 3. The fleet — Alus · Ropus · Potus (all versions)

| Model | Role | v1 | v2 | v3 |
|---|---|---|---|---|
| **alus** | fast everyday assistant | balanced (temp 0.7) | creative (temp 1.1, top_k 100) | precision (temp 0.2, 8k ctx) |
| **ropus** | deep reasoner | step-by-step (8k ctx) | explorer (temp 0.9) | long-context (16k ctx) |
| **potus** | decisive executive | recommender (temp 0.4) | persuasive (temp 0.8) | strict/deterministic (temp 0.1) |

Each version "tweaks the weights' behaviour" via baked-in parameters
(temperature, top_p, top_k, repeat_penalty, context length) and a system
identity — see `modelfiles/*.Modelfile`. Rebuild any of them on a different
base at any time:

```bash
./build_all_models.sh --base qwen2.5:7b --only ropus
```

You can also build/tweak models live from the UI's **🧪 Model Lab** tab —
sliders for every parameter, one-click "Build all 9 models".

> Note: parameter tuning + system prompts change model *behaviour* without
> retraining. For true weight-level changes (fine-tuning/LoRA), train with a
> tool like `llama-factory` or `unsloth`, export to `.gguf`, then feed the
> result to `--weights` — the fleet builds on top of it unchanged.

## 4. Memory

The **🧠 Memory** tab shows:

- **Live model memory** — which models are loaded right now and how much
  RAM/VRAM each uses (from Ollama `/api/ps`), plus this device's reported RAM.
- **Saved memory** — facts you tell it to remember ("My name is…"). They're
  stored locally and injected into every chat, so *all* models remember them.
- **Chat history** — everything stays in your browser's local storage;
  export to JSON or wipe with one click.

## 5. Using it from the Flutter app

The panel is a static page — to embed it in the app, serve `ui/` and open it
in a `WebView`/`InAppWebView`, or link it from a debug menu. It needs no build
step and no dependencies.
