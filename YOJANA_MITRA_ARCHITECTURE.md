# YojanaMitra — Complete System Architecture

## Vision
**"Boli mein sun, scheme mein jod, document khud bhar"**

A voice-first AI assistant that helps Indian citizens discover welfare schemes they qualify for, auto-fills documents, and guides them to nearest CSCs — all in their mother tongue.

---

## User Journey

```
User speaks in Hindi/Marathi/Tamil:
"Mera pati nahi raha, do bachche hain, ghar mein gaaye hain"
     ↓
[Bhashini ASR] → Text in Hindi
     ↓
[LLM + RAG] → Extract: widow, 2 kids, livestock owner, rural
     ↓
[Eligibility Engine] → Match against 1000+ schemes
     ↓
[Rank by benefit] → "₹5000/month × 12 months = ₹60,000/year"
     ↓
[DigiLocker] → Auto-fetch Aadhaar, income cert, caste cert
     ↓
[Form Generator] → Pre-fill application forms
     ↓
[Bhashini TTS] → Speak back in Hindi
"Aap 12 schemes ke liye eligible hain. Top 3 ko dekhen. 
Aadhaar aur income cert already hain. Nearest CSC yahan hai."
```

---

## System Architecture (5 Layers)

### Layer 1: Voice I/O (Bhashini + AI4Bharat)
```
┌─────────────────────────────────────┐
│  Frontend (Web/PWA/Mobile Browser)  │
│  - Mic button → Stream audio        │
│  - Speaker icon → Play TTS          │
│  - Text fallback for accessibility  │
└────────────────┬────────────────────┘
                 │
         ┌───────▼────────┐
         │  Bhashini APIs │
         ├────────────────┤
         │ 1. ASR (Hindi) │
         │ 2. TTS (Hindi) │
         │ 3. Translate   │
         │ 4. NER (Named  │
         │    Entity Rec) │
         └────────────────┘
```

**Free APIs:**
- Bhashini sandbox: `https://sandbox.bhashini.gov.in/ulca/apis` (22 Indic languages)
- AI4Bharat models on HuggingFace (local fallback): `IndicWhisper`, `IndicTTS`, `IndicTrans2`

---

### Layer 2: NLU & RAG (LLM + Scheme Corpus)
```
┌────────────────────────────────────────┐
│  Extracted attributes from speech:     │
│  {                                     │
│    "age": 45,                          │
│    "gender": "female",                 │
│    "family_size": 3,                   │
│    "occupation": "widow",              │
│    "state": "UP",                      │
│    "assets": ["gaaye"],                │
│    "income_category": "BPL",           │
│    "language": "hi"                    │
│  }                                     │
└────────────────────────────────────────┘
                 │
         ┌───────▼──────────────┐
         │  LLM (open-source)   │
         ├──────────────────────┤
         │ Llama-3-8B / Gemma   │
         │ (via Groq free tier  │
         │  or Ollama local)    │
         │                      │
         │ Prompt:              │
         │ "Extract eligibility │
         │  attributes from:    │
         │  [user speech]"      │
         └──────────────────────┘
                 │
        ┌────────▼─────────┐
        │  RAG Pipeline    │
        ├──────────────────┤
        │ 1. Chroma vector │
        │    DB of 1000+   │
        │    schemes       │
        │ 2. Sentence-BERT │
        │    embedding     │
        │ 3. Semantic      │
        │    search        │
        │ 4. Re-rank by    │
        │    ₹benefit      │
        └──────────────────┘
```

**Data Sources:**
- myScheme.gov.in (scrape 1000+ schemes + eligibility rules)
- Stored as JSON + vector embeddings

**Models:**
- LLM: Groq free tier (Llama-3-70B) or Ollama (Llama-2-7B local)
- Embeddings: `sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2`
- Vector DB: Chroma (local, free)

---

### Layer 3: Eligibility Engine (Classifier + Business Rules)
```
┌──────────────────────────────────────┐
│  Eligibility Classifier              │
├──────────────────────────────────────┤
│ scikit-learn RandomForest trained on:│
│ - Demographic → Scheme labels        │
│ - 70,000 synthetic + real examples   │
│                                      │
│ Output: P(eligible) for each scheme  │
│ Threshold: 0.65 → "Show this"        │
└──────────────────────────────────────┘
         ↓
┌──────────────────────────────────────┐
│  Business Rules Engine               │
├──────────────────────────────────────┤
│ Hard filters:                        │
│ - PM-KISAN: income < ₹2L, land ≤ 2ha│
│ - Widow Pension: age ≥ 18, ≤ 60     │
│ - PM-JAY: BPL + APL priority        │
│ - Jan Aushadhi: anyone (free)        │
└──────────────────────────────────────┘
         ↓
┌──────────────────────────────────────┐
│  Final Ranked List                   │
├──────────────────────────────────────┤
│ [                                    │
│   {                                  │
│     "name": "PM Matru Vandana",       │
│     "benefit": "₹5,000 × 3 = ₹15k",  │
│     "match_score": 0.94,             │
│     "documents_needed": [             │
│       "Aadhaar",                      │
│       "Delivery cert",                │
│       "Bank account"                  │
│     ]                                │
│   },                                 │
│   ...                                │
│ ]                                    │
└──────────────────────────────────────┘
```

---

### Layer 4: Document Auto-Fill (DigiLocker + OCR)
```
┌─────────────────────────────────────┐
│  DigiLocker API (via API Setu)      │
├─────────────────────────────────────┤
│ Sandbox: sandbox.api-setu.in        │
│                                     │
│ Fetches (with user consent):        │
│ 1. Aadhaar XML                      │
│ 2. Income Certificate               │
│ 3. Caste Certificate                │
│ 4. Land ownership documents         │
│ 5. Death Certificate (widow)        │
│ 6. Bank passbook                    │
└─────────────────────────────────────┘
         │
┌────────▼───────────────────────────┐
│  OCR (TrOCR / Tesseract)           │
├────────────────────────────────────┤
│ Extract text from:                 │
│ - Handwritten income certs         │
│ - Land records (Pattas)            │
│ - Ration card                      │
└────────────────────────────────────┘
         │
┌────────▼────────────────────────────┐
│  Form Generator (Jinja2 templates)  │
├─────────────────────────────────────┤
│ Template per scheme:                │
│ - PM-KISAN: Pre-fill name, Aadhaar,│
│   land details                      │
│ - Widow Pension: Pre-fill age,      │
│   family size, death cert           │
│ - PMJAY: Pre-fill BPL status        │
│                                     │
│ Output: PDF ready for CSC           │
└─────────────────────────────────────┘
```

**Free APIs:**
- DigiLocker via API Setu sandbox
- OCR: TrOCR (HuggingFace) or Tesseract (local)

---

### Layer 5: Backend (FastAPI)
```
FastAPI Application
├── /api/voice/stream
│   ├── Input: audio stream (webm/wav)
│   ├── Bhashini ASR → text
│   └── Output: JSON {"text": "...", "language": "hi"}
│
├── /api/schemes/search
│   ├── Input: {"attributes": {...}, "language": "hi"}
│   ├── RAG + Eligibility engine
│   └── Output: [scheme1, scheme2, ...]
│
├── /api/digilocker/consent
│   ├── Initiate OAuth flow with API Setu
│   └── Return consent URL for user
│
├── /api/form/generate
│   ├── Input: {scheme_id, documents_fetched}
│   ├── Jinja2 template rendering
│   └── Output: PDF
│
├── /api/tts/speak
│   ├── Input: {text, language}
│   ├── Bhashini TTS
│   └── Output: audio stream
│
└── /api/location/csc
    ├── Input: {lat, lng}
    ├── Query CSC database
    └── Output: [{name, addr, hours, distance}, ...]
```

---

## Tech Stack

### Frontend
```
Next.js 14 (App Router)
├── React for UI components
├── Tailwind CSS for styling
├── shadcn/ui for accessible components
├── Web Audio API for microphone
├── PWA (service worker) for offline
└── Vercel for deployment (free tier)
```

### Backend
```
FastAPI + Python 3.11
├── Bhashini SDK (language APIs)
├── LangChain (RAG framework)
├── Chroma (vector DB)
├── scikit-learn (classifier)
├── Jinja2 (form templates)
├── PyPDF2 (PDF generation)
├── requests (API calls)
└── Railway.io or Fly.io for deployment
```

### LLMs & Models
```
Primary (Inference):
├── Llama-3-8B via Groq free tier (unlimited requests)
├── Bhashini ASR + TTS
└── sentence-transformers/paraphrase-multilingual

Fallback (Local):
├── AI4Bharat IndicWhisper (ASR, ~1GB)
├── IndicTTS (TTS, ~500MB)
└── Ollama (Llama-2-7B, ~4GB)

Data:
├── Chroma vector DB (1000 schemes)
├── CSC location DB (400k+ CSCs)
└── Jan Aushadhi locations (12k+ centers)
```

### APIs (All Free)
```
Government:
├── Bhashini (ASR, TTS, translation)
├── API Setu (DigiLocker, Aadhaar consent)
├── myScheme.gov.in (scheme data)
├── data.gov.in (census, district data)
├── Jan Aushadhi (medicine list)
└── PMJAY (hospital empanelment)

Third-party:
├── Groq (LLM inference, free tier: 30 req/min)
├── OpenRouter (LLM fallback)
└── HuggingFace (model hosting, free)

Mapping:
├── OpenStreetMap / Leaflet (CSC location)
└── Nominatim (reverse geocoding)
```

---

## Data Models

### User Profile
```json
{
  "id": "unique_uuid",
  "phone": "+91xxxxxxxxxx",
  "name": "Ramakali",
  "age": 45,
  "gender": "F",
  "state": "UP",
  "district": "Etah",
  "occupation": "farmer",
  "family_size": 3,
  "income_annual": 60000,
  "income_category": "BPL",
  "marital_status": "widow",
  "assets": {
    "land_ha": 0,
    "livestock": ["cow", "goat"],
    "bank_account": true,
    "ration_card": "APL"
  },
  "languages": ["hi", "en"],
  "aadhaar_linked": true,
  "digilocker_consent": "2026-05-09T14:30:00Z",
  "documents_fetched": ["aadhaar", "income_cert"],
  "created_at": "2026-05-01T10:00:00Z"
}
```

### Scheme Object
```json
{
  "id": "pm-matru-vandana-yojana",
  "name": "PM Matru Vandana Yojana",
  "ministry": "MWCD",
  "category": "maternal-health",
  "description": "Cash assistance to pregnant women",
  "benefit": 5000,
  "benefit_frequency": "quarterly",
  "benefit_total": 15000,
  "benefit_description": "₹5,000 × 3 installments",
  "eligibility": {
    "pregnant_women_only": true,
    "min_age": 18,
    "max_age": null,
    "bpl": null,
    "income_limit": null,
    "documents_required": [
      "Aadhaar",
      "Delivery/Pregnancy certificate",
      "Bank account"
    ]
  },
  "state_variations": {
    "bihar": {
      "additional_docs": ["land_certificate"]
    }
  },
  "application_mode": "online_csc",
  "ministry_contact": "www.pmmvy.nic.in",
  "embedding": [0.234, 0.567, ...],  // Sentence-BERT embedding
  "keywords": ["maternity", "pregnancy", "cash", "women"],
  "eligibility_score_weights": {
    "pregnant_women": 0.9,
    "age_18_45": 0.8,
    "married": 0.6,
    "rural": 0.5
  }
}
```

### Matched Scheme Object
```json
{
  "scheme": {...scheme_object},
  "match_score": 0.94,
  "match_reasons": [
    "Pregnant woman (high confidence)",
    "Age 18-45 (perfect match)",
    "Has bank account (required)",
    "Rural (often preferred)"
  ],
  "missing_documents": [],
  "available_documents": ["aadhaar"],
  "next_steps": [
    "Collect delivery/pregnancy certificate from ANM/ASHA",
    "Go to nearest CSC with Aadhaar + bank passbook",
    "Apply online via PMJBY portal"
  ],
  "nearest_csc": {
    "name": "Ramgarh CSC",
    "lat": 28.5242,
    "lng": 78.8123,
    "distance_km": 3.2,
    "hours": "10 AM - 5 PM",
    "phone": "+91-9876543210",
    "address": "Gram Panchayat, Ramgarh, Etah, UP"
  }
}
```

---

## 6-Week Development Roadmap

| Week | Task | Deliverable |
|------|------|-------------|
| **1** | **Data & Infrastructure** | Scrape myScheme (1000+ schemes into JSON), set up FastAPI + Next.js repo, Chroma setup with embeddings |
| **2** | **RAG + Eligibility Engine** | Implement LangChain RAG pipeline, train classifier on synthetic data, test retrieval quality (P@3 > 0.8) |
| **3** | **Voice I/O (Bhashini)** | Integrate Bhashini ASR + TTS, test in 3 languages (Hindi, Marathi, Tamil), Web Audio API frontend |
| **4** | **DigiLocker + Document Auto-fill** | Sandbox API Setu DigiLocker, OAuth flow, Jinja2 form templates for 5 top schemes, PDF generation |
| **5** | **UI/UX + Integration** | Build mobile-first PWA (Next.js), wire all APIs, test end-to-end (speech → schemes → forms), accessibility audit |
| **6** | **Testing + Deployment** | User testing with 5–10 real users, demo video, deploy backend (Railway/Fly.io), frontend (Vercel), hardcode CSC locations |

---

## Success Metrics

- **30 schemes matched** in < 3 seconds
- **ASR confidence > 85%** for Hindi/Marathi speakers
- **Document auto-fill > 70%** (pre-fills 70% of required fields)
- **Mobile-first**, works on 2G (5 KB gzipped baseline)
- **Zero cost** to run (all free tiers)
- **5+ real users test** by week 6

---

## Known Limitations & Fallbacks

1. **DigiLocker consent**: Sandbox mode only; production needs MeitY approval (free)
2. **ASR accuracy**: 85–90% for clear audio; noisy backgrounds → text fallback
3. **Scheme eligibility**: Based on uploaded data.gov.in census + myScheme rules (not real-time income verification)
4. **Form filling**: 70% automation; 30% requires manual entry (acceptable for PoC)
5. **CSC locations**: Database updated quarterly; real-time availability not available

---

## Deployment

- **Backend**: Railway.io free tier (512 MB RAM, enough for Llama-3-8B via Groq)
- **Frontend**: Vercel free (Next.js optimized)
- **Vector DB**: Chroma local file storage (300 MB for 1000 schemes)
- **LLM**: Groq free tier (no local inference needed)

**Total monthly cost: ₹0**

---

This is the complete blueprint. Ready to build?
