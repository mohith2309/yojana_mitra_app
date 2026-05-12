# BharatMitra Android MVP Setup

## What is already built

- Flutter Android app with clean mobile UI.
- Local/free rule-based welfare scheme matching.
- BharatMitra local service cards for mandi advice, AQI planning, flood readiness, student guidance, and civic report drafts.
- Sample user prompts for widow support, farmers, students, housing, LPG.
- Voice input through Android speech recognition (`speech_to_text`).
- Text-to-speech result reading (`flutter_tts`).
- In-app reminders.
- Saved/bookmarked schemes with `shared_preferences`.
- Mock DigiLocker document readiness card.
- Shareable text checklist.
- PDF checklist export/share.
- Official myScheme search links.
- Optional backend AI card in the app for Google/Gemma fast replies and NVIDIA-hosted Mistral auto tasks.
- Backend stub endpoints for the new BharatMitra service modules.
- No paid API required for current build.
- Backend gateway starter in `backend/` for future API keys.

## Run locally

```bash
cd /Users/mohith/Downloads/yojana_mitra_app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

APK output:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

Install on connected Android device:

```bash
flutter install
```

Or run directly:

```bash
flutter run
```

## Android permissions already added

- `INTERNET` for official links and future API calls.
- `RECORD_AUDIO` for voice input.

## API integration plan

Do not put production API keys directly inside the APK. Use a small backend for real API calls.

Recommended backend:

```text
FastAPI or Node.js server
Flutter app -> backend -> govt/API/AI providers
```

Backend starter already exists:

```text
backend/main.py
backend/.env.example
backend/requirements.txt
backend/README.md
```

Run backend:

```bash
cd /Users/mohith/Downloads/yojana_mitra_app/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Health check:

```bash
curl http://127.0.0.1:8000/health
```

Interactive API docs:

```text
http://127.0.0.1:8000/docs
```

Android emulator backend URL:

```text
http://10.0.2.2:8000
```

The Flutter app has a backend URL field prefilled with this emulator URL. On a real phone, replace it in the app with your Mac LAN IP, for example `http://192.168.1.7:8000`.

### 0. BharatMitra service modules

Current app has local/demo guidance for:

- Farmer mandi price advisor.
- AQI activity planner.
- Flood and disaster alert checklist.
- Student career and scholarship guide.
- Civic report draft helper.

Backend demo endpoints already exist:

```text
POST /mandi/advice
POST /aqi/plan
POST /flood/risk
POST /career/guide
POST /civic/report-draft
```

They return safe local placeholder responses without API keys. Replace them with live government/open-data calls only on the backend.

### 1. myScheme

Current app opens official myScheme search links.

Next step:

- Build a backend scraper/cache or use an approved official data source.
- Store schemes as normalized JSON.
- Sync the JSON to the app or serve it through the backend.

### 2. Bhashini / AI4Bharat

Current app uses Android speech + TTS for free local device capability.

Next step:

- Add Bhashini ASR/TTS in backend after getting credentials.
- Use AI4Bharat models if you want open-source Indic language support.

### 3. API Setu / DigiLocker

Current app has a mock DigiLocker card.

Next step:

- Get API Setu/DigiLocker sandbox access.
- Implement consent flow in backend.
- Return only document availability to app, not raw Aadhaar/PAN unless strictly needed.

### 4. data.gov.in

Next step:

- Get free data.gov.in API key.
- Use it for district-level filters, CSC/office data, or demographic hints.

### 5. NVIDIA / AI model choices

From the NVIDIA Free Endpoint list, use these in this order:

```text
Consumer fast endpoint: google/gemma-3n-e4b-it
Backend auto-task endpoint: mistralai/mistral-medium-3.5-128b
Reasoning endpoint: mistralai/mistral-medium-3.5-128b
Fallback endpoint: mistralai/mistral-large-3-675b-instruct-2512
Small/cheap endpoint: nvidia/nemotron-mini-4b-instruct
Safety filter: meta/llama-guard-4-12b
PII detection: nvidia/gliner-pii
RAG embedding later: nvidia/llama-3_2-nemoretriever-300m-embed-v1
RAG reranking later: nv-rerank-qa-mistral-4b:1 through /v1/retrieval/nvidia/reranking
Future multimodal input: microsoft/phi-4-multimodal-instruct
Future voice/TTS/audio cleanup: nvidia/magpie-tts-zeroshot, nvidia/studiovoice
```

Use `consumer` mode for fast user-facing explanation. Use `auto` mode for backend tasks like profile extraction, eligibility reasoning, form help, and multi-step automation.

Consumer mode uses a stable Google free endpoint:

```text
model=google/gemma-3n-e4b-it
temperature=0.2
top_p=0.7
max_tokens=512
chat_template_kwargs.enable_thinking=true
```

Auto mode uses Mistral Medium 3.5:

```text
model=mistralai/mistral-medium-3.5-128b
temperature=0.7
top_p=1
max_tokens=16384
reasoning_effort=high
chat_template_kwargs.enable_thinking=true
chat_template_kwargs.clear_thinking=false
```

Do not use huge downloadable models for this Android MVP. Keep AI calls on the backend.

The backend already includes:

```text
POST /profile/extract
POST /nvidia/chat
POST /nvidia/pii-detect
POST /nvidia/rerank
POST /digilocker/mock-documents
POST /mandi/advice
POST /aqi/plan
POST /flood/risk
POST /career/guide
POST /civic/report-draft
GET  /data-gov/resource/{resource_id}
POST /bhashini/asr-placeholder
```

These endpoints work as safe placeholders until keys are added to `backend/.env`.

Collected data.gov.in resource IDs:

```env
MANDI_DATA_GOV_RESOURCE_ID=9ef84268-d588-465a-a308-a864a43d0070
AQI_DATA_GOV_RESOURCE_ID=3b01bcb8-0b14-4abf-b6f2-c1bfd384ba69
FLOOD_DATA_GOV_RESOURCE_ID=6c05cd1b-ed59-40c2-bc31-e314f39c6971
SOIL_MOISTURE_DATA_GOV_RESOURCE_ID=4554a3c8-74e3-4f93-8727-8fd92161e345
CIVIC_DIRECTORY_DATA_GOV_RESOURCE_ID=71818d1a-c114-46cb-aa9b-56ed70d4bc4a
CIVIC_DIRECTORY_BACKUP_DATA_GOV_RESOURCE_ID=1a6c26ed-d67c-40ea-aa20-d38d35f341a5
LGD_VILLAGES_DATA_GOV_RESOURCE_ID=c967fe8f-69c4-42df-8afc-8a2c98057437
LGD_VILLAGES_PIN_DATA_GOV_RESOURCE_ID=f17a1608-5f10-4610-bb50-a63c80d83974
```

Career guide currently uses official links instead of weak data.gov.in Skill India statistics:

```text
https://www.skillindiadigital.gov.in/
https://www.apprenticeshipindia.gov.in/
https://scholarships.gov.in/
```

The Android app can call `/health` and `/nvidia/chat` from the `Backend AI` card. It still works offline/local if the backend is not running.

Important: never paste API keys into app source, Codex prompts, chat, or GitHub. If a key is shared publicly, rotate/revoke it in NVIDIA and put the replacement only in `backend/.env`.

## What Codex should test

1. App launches as `BharatMitra` on Android.
2. Confirm `BharatMitra local services` appears below the main input.
3. Tap `Use this prompt` on each local service card and confirm the prompt fills the main box.
4. Tap `Find schemes` with starter profile.
5. Confirm `Widow Pension Support` appears.
6. Tap `Use voice`; Android should ask for microphone permission.
7. Tap `Read aloud`; TTS should speak results.
8. Tap bookmark on a scheme; saved scheme card should appear.
9. Tap `Export PDF`; share sheet should open.
10. Tap `Share text`; share sheet should open.
11. Tap `Official`; browser should open myScheme search.
12. Optional backend: run `curl http://127.0.0.1:8000/health`.
13. Optional backend stubs: test `/mandi/advice`, `/aqi/plan`, `/flood/risk`, `/career/guide`, and `/civic/report-draft` in `/docs`.
14. Optional app backend: open `Backend AI`, tap `Check`, then `Fast answer` and `Auto task` after backend has an NVIDIA key.

## Codex handoff prompt

Use this with Codex for the remaining integration half:

```text
You are working in /Users/mohith/Downloads/yojana_mitra_app.

Goal: replace BharatMitra demo service stubs with real backend integrations while keeping API keys out of Flutter and GitHub.

Do not remove the existing local/offline Flutter behavior. Add graceful fallback when any API key, resource ID, or public feed is missing.

Tasks:
1. Add env-configured resource IDs/feed URLs for mandi prices, AQI, flood/disaster alerts, scholarships/skills, and civic grievance directories.
2. Implement live backend fetchers behind these existing endpoints: /mandi/advice, /aqi/plan, /flood/risk, /career/guide, /civic/report-draft.
3. Normalize responses into simple JSON that the Flutter app can consume without exposing secrets.
4. Add small backend tests for missing-key fallback and one mocked successful response per endpoint.
5. Optionally wire Flutter service cards to call these endpoints, but keep local demo text if backend is offline.

Verify:
python3 -m py_compile backend/main.py backend/test_nvidia.py
flutter analyze
flutter test
flutter build apk --debug
```

## Remaining production work

- Replace demo scheme list with real cached scheme data.
- Connect BharatMitra service cards to backend API layer when credentials/data feeds are available.
- Add Bhashini/API Setu/data.gov.in credentials through backend env vars.
- Add real DigiLocker sandbox consent flow.
- Add real mandi, AQI, flood/disaster, scholarship/skill, and civic-grievance data sources.
- Add proper Indic language localization strings.
- Add more tests for profile extraction and scheme ranking.
