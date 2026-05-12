# BharatMitra Backend Gateway

BharatMitra uses this FastAPI gateway to keep provider credentials out of the
Flutter app, tests, docs, and GitHub. Real secrets belong only in
`backend/.env`; commit only `.env.example`.

## Local Setup

```bash
cd /Users/mohith/Downloads/yojana_mitra_app/backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Open the interactive docs:

```text
http://127.0.0.1:8000/docs
```

If the Flutter app runs in the Android emulator, use the host URL:

```text
http://10.0.2.2:8000
```

On a physical Android phone, use the Mac LAN IP, for example
`http://192.168.1.7:8000`, and keep both devices on the same Wi-Fi.

## Verification

```bash
python3 -m py_compile main.py test_nvidia.py
.venv/bin/python -m unittest test_service_integrations.py
curl http://127.0.0.1:8000/health
```

Direct NVIDIA smoke test after adding a rotated key to `backend/.env`:

```bash
python test_nvidia.py "Explain BharatMitra in one sentence"
NVIDIA_TEST_MODE=auto python test_nvidia.py "Extract eligibility attributes from: I am a small farmer"
```

## Environment Variables

Required only when calling NVIDIA-backed endpoints:

```env
NVIDIA_API_KEY=
```

Required only when calling data.gov.in live resources:

```env
DATA_GOV_API_KEY=
```

Common NVIDIA settings:

```env
NVIDIA_BASE_URL=https://integrate.api.nvidia.com/v1
NVIDIA_CONSUMER_MODEL=google/gemma-3n-e4b-it
NVIDIA_AUTOTASK_MODEL=mistralai/mistral-medium-3.5-128b
NVIDIA_REASONING_MODEL=mistralai/mistral-medium-3.5-128b
NVIDIA_FALLBACK_MODEL=mistralai/mistral-large-3-675b-instruct-2512
NVIDIA_PII_MODEL=nvidia/gliner-pii
NVIDIA_RERANK_MODEL=nv-rerank-qa-mistral-4b:1
NVIDIA_RERANK_URL=https://ai.api.nvidia.com/v1/retrieval/nvidia/reranking
NVIDIA_REASONING_EFFORT=high
```

Data.gov resource IDs currently used by service endpoints:

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

Optional public feed URLs can override or supplement data.gov sources:

```env
MANDI_FEED_URL=
AQI_FEED_URL=
FLOOD_ALERT_FEED_URL=
CIVIC_DIRECTORY_FEED_URL=
```

## Response Modes

Most citizen-service endpoints return:

- `mode: "live"` when a configured feed or data.gov source returns records.
- `mode: "local_fallback"` when keys, resource IDs, or public feeds are missing
  or unavailable.

Citizen service endpoints (mandi, aqi, flood, civic) return HTTP `200` with
`mode: "local_fallback"` when provider keys are missing. AI endpoints like
`/nvidia/pii-detect` and `/nvidia/rerank` also return `200` with
`mode: "local_fallback"` instead of `503`, so Flutter can keep working
without pretending an AI provider was called.

## API Reference

### GET /health

Returns whether the gateway is running and which integrations are configured.

```bash
curl http://127.0.0.1:8000/health
```

Example response:

```json
{
  "ok": true,
  "configured": {
    "nvidia": false,
    "bhashini": false,
    "api_setu": false,
    "data_gov": false,
    "live_modules": {
      "mandi": true,
      "aqi": true,
      "flood": true,
      "career": false,
      "civic": true
    },
    "demo_modules": true
  }
}
```

### POST /mandi/advice

Gives mandi selling guidance for a crop and location. Uses `MANDI_FEED_URL` or
`MANDI_DATA_GOV_RESOURCE_ID` plus `DATA_GOV_API_KEY` when configured; otherwise
returns local fallback advice.

Request:

```json
{
  "crop": "onion",
  "district": "Nashik",
  "state": "Maharashtra",
  "expected_quantity_kg": 500
}
```

Example:

```bash
curl -X POST http://127.0.0.1:8000/mandi/advice \
  -H 'Content-Type: application/json' \
  -d '{"crop":"onion","district":"Nashik","state":"Maharashtra","expected_quantity_kg":500}'
```

Example fallback response:

```json
{
  "mode": "local_fallback",
  "input": {
    "crop": "onion",
    "district": "Nashik",
    "state": "Maharashtra"
  },
  "prices": [],
  "advice": [
    "Compare onion prices in at least two mandis near Nashik before selling.",
    "Subtract transport, loading, commission, and waiting cost from the quoted price.",
    "If prices are volatile, consider selling in parts instead of one full lot.",
    "Approx quantity noted: 500 kg."
  ],
  "source_status": [
    {
      "source": "mandi_feed",
      "configured": false,
      "ok": false,
      "reason": "feed URL missing"
    },
    {
      "source": "mandi_data_gov",
      "configured": true,
      "ok": false,
      "reason": "DATA_GOV_API_KEY missing"
    }
  ],
  "fallback_message": "Live mandi source is not configured or unavailable, so local advice is shown."
}
```

### POST /aqi/plan

Turns an AQI value or live AQI record into simple activity guidance. Uses
`AQI_FEED_URL` or `AQI_DATA_GOV_RESOURCE_ID` plus `DATA_GOV_API_KEY` when
configured.

Request:

```json
{
  "location": "Delhi",
  "aqi": 210,
  "activities": ["school run", "outdoor work", "travel"]
}
```

Example:

```bash
curl -X POST http://127.0.0.1:8000/aqi/plan \
  -H 'Content-Type: application/json' \
  -d '{"location":"Delhi","aqi":210,"activities":["school run","outdoor work"]}'
```

Example fallback response:

```json
{
  "mode": "local_fallback",
  "location": "Delhi",
  "aqi": 210,
  "reading": null,
  "band": "very_poor",
  "guidance": "Avoid unnecessary heavy outdoor activity and follow official local advisories.",
  "activity_plan": [
    "school run: plan with current band 'very_poor' in mind.",
    "outdoor work: plan with current band 'very_poor' in mind."
  ],
  "source_status": [
    {
      "source": "aqi_feed",
      "configured": false,
      "ok": false,
      "reason": "feed URL missing"
    },
    {
      "source": "aqi_data_gov",
      "configured": true,
      "ok": false,
      "reason": "DATA_GOV_API_KEY missing"
    }
  ],
  "fallback_message": "Live AQI source is not configured or unavailable, so local AQI input is used."
}
```

### POST /flood/risk

Builds a flood/disaster readiness checklist from live alerts, rainfall records,
soil moisture records, or local fallback input.

Request:

```json
{
  "district": "Patna",
  "state": "Bihar",
  "alert_type": "heavy rain",
  "water_level_m": 54.2,
  "danger_level_m": 54
}
```

Example:

```bash
curl -X POST http://127.0.0.1:8000/flood/risk \
  -H 'Content-Type: application/json' \
  -d '{"district":"Patna","state":"Bihar","alert_type":"heavy rain","water_level_m":54.2,"danger_level_m":54}'
```

Example response:

```json
{
  "mode": "local_fallback",
  "district": "Patna",
  "state": "Bihar",
  "risk": "high",
  "alerts": [],
  "rainfall_records": [],
  "soil_moisture_records": [],
  "checklist": [
    "Follow district administration, IMD, CWC, NDMA, and local police alerts.",
    "Keep Aadhaar, bank passbook, ration card, and phone in a waterproof bag.",
    "Charge phone, power bank, and torch before waterlogging worsens.",
    "Avoid crossing flooded roads, bridges, and fast-moving water."
  ],
  "source_status": [
    {
      "source": "flood_feed",
      "configured": false,
      "ok": false,
      "reason": "feed URL missing"
    },
    {
      "source": "flood_data_gov",
      "configured": true,
      "ok": false,
      "reason": "DATA_GOV_API_KEY missing"
    },
    {
      "source": "soil_moisture_data_gov",
      "configured": true,
      "ok": false,
      "reason": "DATA_GOV_API_KEY missing"
    }
  ],
  "fallback_message": "Live disaster source is not configured or unavailable, so local safety checklist is shown."
}
```

### POST /civic/report-draft

Drafts a concise civic complaint and optionally looks up local bodies or village
directory records from civic data.gov resources.

Request:

```json
{
  "issue": "pothole",
  "location": "MG Road",
  "landmark": "bus stop",
  "risk": "traffic slowdown and two-wheeler accident risk",
  "state": "Maharashtra",
  "pincode": "411001"
}
```

Example:

```bash
curl -X POST http://127.0.0.1:8000/civic/report-draft \
  -H 'Content-Type: application/json' \
  -d '{"issue":"pothole","location":"MG Road","landmark":"bus stop","risk":"two-wheeler accident risk","state":"Maharashtra","pincode":"411001"}'
```

Example response:

```json
{
  "mode": "local_fallback",
  "draft": "Subject: Request to fix pothole at MG Road\n\nRespected Sir/Madam,\nPlease inspect and fix pothole at MG Road, near bus stop. This is causing two-wheeler accident risk. Kindly register this complaint, share the complaint number, and update the expected resolution date.\n\nThank you.",
  "contacts": [],
  "attach": ["clear photo", "short video if safe", "landmark", "date and time"],
  "escalation": ["ward office", "municipal helpline", "state grievance portal"],
  "source_status": [
    {
      "source": "civic_directory_feed",
      "configured": false,
      "ok": false,
      "reason": "feed URL missing"
    }
  ],
  "fallback_message": "Live civic directory is not configured or unavailable, so local complaint draft is shown."
}
```

### POST /nvidia/chat

Calls NVIDIA chat completions. Requires `NVIDIA_API_KEY`. Consumer mode uses the
fast consumer model and omits `reasoning_effort`; non-consumer modes include
`reasoning_effort`.

Request:

```json
{
  "mode": "consumer",
  "prompt": "Explain widow pension support in simple words",
  "temperature": 0.2,
  "top_p": 0.7,
  "max_tokens": 512
}
```

Auto-task request:

```json
{
  "mode": "auto",
  "prompt": "Extract missing details for this welfare application",
  "reasoning_effort": "high"
}
```

Example:

```bash
curl -X POST http://127.0.0.1:8000/nvidia/chat \
  -H 'Content-Type: application/json' \
  -d '{"mode":"consumer","prompt":"Explain PM-KISAN in one short paragraph"}'
```

Example success response:

```json
{
  "mode": "consumer",
  "answer": "PM-KISAN is a central government income support scheme for eligible farmer families. Check the official portal or CSC before applying.",
  "model": "google/gemma-3n-e4b-it",
  "content": "PM-KISAN is a central government income support scheme for eligible farmer families. Check the official portal or CSC before applying.",
  "reasoning_content": null
}
```

Missing-key response:

```json
{
  "detail": "NVIDIA_API_KEY is not configured"
}
```

### POST /nvidia/pii-detect

Calls NVIDIA GLINER PII detection. Requires `NVIDIA_API_KEY`.

Request:

```json
{
  "text": "My name is Asha Sharma and my phone is 9999999999",
  "labels": ["first_name", "last_name", "phone_number"],
  "threshold": 0.4,
  "chunk_length": 384,
  "overlap": 128,
  "flat_ner": false
}
```

Example:

```bash
curl -X POST http://127.0.0.1:8000/nvidia/pii-detect \
  -H 'Content-Type: application/json' \
  -d '{"text":"My phone is 9999999999","labels":["phone_number"],"threshold":0.4,"chunk_length":384,"overlap":128}'
```

Example response (with NVIDIA key):

```json
{
  "model": "nvidia/gliner-pii",
  "result": {
    "entities": [
      {
        "text": "9999999999",
        "label": "phone_number",
        "score": 0.98
      }
    ]
  }
}
```

Missing-key response (local fallback):

```json
{
  "mode": "local_fallback",
  "model": "local/pii-rules",
  "result": {
    "entities": []
  }
}
```

### POST /nvidia/rerank

Calls the NVIDIA retrieval reranking endpoint. This endpoint does not use chat
completions. Requires `NVIDIA_API_KEY`.

Request:

```json
{
  "query": "farmer income support",
  "passages": [
    "PM-KISAN supports eligible farmer families with direct income support.",
    "Scholarships help students pay education fees."
  ],
  "model": "nv-rerank-qa-mistral-4b:1"
}
```

Example:

```bash
curl -X POST http://127.0.0.1:8000/nvidia/rerank \
  -H 'Content-Type: application/json' \
  -d '{"query":"farmer income support","passages":["PM-KISAN supports farmers","Scholarships support students"]}'
```

Example response (with NVIDIA key):

```json
{
  "rankings": [
    {
      "index": 0,
      "logit": 12.4
    },
    {
      "index": 1,
      "logit": 2.1
    }
  ]
}
```

Missing-key response (local fallback):

```json
{
  "mode": "local_fallback",
  "model": "local/word-overlap-rerank",
  "rankings": [
    {
      "index": 0,
      "score": 0.95,
      "text": "PM-KISAN supports farmers"
    },
    {
      "index": 1,
      "score": 0.2,
      "text": "Scholarships support students"
    }
  ]
}
```

## Supporting Endpoints

These are also present in the gateway:

```text
POST /profile/extract
POST /digilocker/mock-documents
GET  /data-gov/resource/{resource_id}
POST /bhashini/asr-placeholder
```

`/data-gov/resource/{resource_id}` requires `DATA_GOV_API_KEY`.
`/bhashini/asr-placeholder` requires `BHASHINI_API_KEY`.

## Secret Handling

- Do not put API keys in Flutter, tests, docs, or GitHub.
- Do not paste API keys into prompts or issue trackers.
- Keep real keys only in `backend/.env`.
- If a key is exposed, rotate/revoke it and replace it only in `backend/.env`.
