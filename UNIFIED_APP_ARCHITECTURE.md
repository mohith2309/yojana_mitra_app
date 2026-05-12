# BharatSeva — Unified Voice-First Citizen AI Platform
**One app. Five problems. Zero cost.**

## Vision
A single, integrated AI assistant that helps Indian citizens navigate welfare schemes, find medicine substitutes, check mandi prices, avoid pollution zones, and get disaster warnings—all via voice in their language.

---

## Problem Map

| Problem | Domain | Users | Impact | Our Solution |
|---------|--------|-------|--------|--------------|
| **40% welfare unclaimed** | YojanaMitra | 600M poor citizens | ₹10T+ unclaimed/year | Voice-first scheme discovery |
| **Jan Aushadhi not used** | AushadhSathi | 100M poor patients | ₹50k/year savings missed | Medicine composition matching |
| **Mandi prices hidden** | Annapurna | 150M farmers | ₹5-10k losses/year | Real-time price + forecasts |
| **Pollution routes unclear** | VayuMitra | 50M urban/rural | Health damage ₹20k+/year | AQI-aware route planning |
| **Flood warnings missed** | PathSetu | 50M flood-prone | Lives lost, ₹10k+ property damage | Geolocation + SMS alerts |

---

## Unified User Journey

```
User opens app
    ↓
Hears: "नमस्ते! क्या आप welfare, medicine, prices, pollution, या flood के बारे में जानना चाहते हैं?"
    ↓
User speaks: "Mera behan pregnant hai, medicine sasta chahiye"
    ↓
[LLM] → Detect: pregnant woman + medicine price concern
    ↓
[Multi-module search]:
  → YojanaMitra: "PM Matru Vandana ₹5000"
  → AushadhSathi: "Prenatal vitamins ₹50 (Jan Aushadhi vs ₹500)"
  → Annapurna: "Local vegetable prices for nutrition"
    ↓
App speaks back in Hindi: "Aapke liye 3 schemes aur sasti medicine. Yeh dekhen."
    ↓
Show unified results with:
  - Schemes to apply for
  - Medicines to buy (with CSC/Jan Aushadhi centers)
  - Nutrition prices from nearest mandi
  - Download combined form
```

---

## Architecture: 5-Domain Unified Platform

### Layer 1: Voice I/O (Bhashini - All Domains)
```
User speaks in Hindi/Marathi/Tamil/etc
    ↓
[Bhashini ASR]
    ↓
[Master NLU Classifier] → Detect: which domain(s)?
  - "scheme" → route to YojanaMitra
  - "medicine/दवा/dawa" → route to AushadhSathi
  - "price/mandi/भाव" → route to Annapurna
  - "pollution/AQI/हवा" → route to VayuMitra
  - "flood/warning/बाढ़" → route to PathSetu
  - "multi" → route to multiple domains
    ↓
[Bhashini TTS] → Speak results in user's language
```

### Layer 2: Unified Data Models

```python
class UserProfile:
    # Core (reused across all domains)
    id: str
    phone: str
    name: str
    age: int
    gender: str
    state: str
    district: str
    languages: List[str]
    location: {lat, lng}  # For pollution & flood alerts
    
    # Domain-specific attributes stored as flexible dict
    attributes: {
        # YojanaMitra
        "marital_status": "widow",
        "family_size": 3,
        "annual_income": 60000,
        
        # AushadhSathi
        "health_conditions": ["diabetes", "pregnancy"],
        "allergies": ["paracetamol"],
        
        # Annapurna
        "occupation": "farmer",
        "crops": ["wheat", "rice"],
        
        # VayuMitra
        "daily_commute": "truck driver",
        "respiratory_condition": "asthma",
        
        # PathSetu
        "flood_prone_area": True,
        "phone_alert_enabled": True
    }
```

### Layer 3: Domain Modules (Pluggable)

```
Backend (FastAPI)
├── /api/master/search
│   └── Auto-routes to 1+ domains
│
├── /api/yojana/... (Welfare Schemes)
│   ├── /search
│   ├── /form/generate
│   └── /csc/nearby
│
├── /api/aushadh/... (Medicine)
│   ├── /search
│   ├── /composition/match
│   └── /jan-aushadhi/nearby
│
├── /api/annapurna/... (Mandi Prices)
│   ├── /prices/today
│   ├── /forecast
│   └── /nutrition/plan
│
├── /api/vayu/... (Pollution & Routes)
│   ├── /aqi/current
│   ├── /route/safe
│   └── /health/advisory
│
└── /api/path/... (Disaster Warnings)
    ├── /flood/alert
    ├── /weather/watch
    └── /sms/subscribe
```

### Layer 4: Shared Infrastructure

```
┌─────────────────────────────────────┐
│ Vector DB (Chroma)                  │
├─────────────────────────────────────┤
│ - 1000+ schemes (YojanaMitra)       │
│ - 5000+ medicine combos (AushadhSathi)
│ - 50+ crop prices (Annapurna)       │
│ - AQI routes (VayuMitra)            │
│ - Flood zones (PathSetu)            │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│ LLM (Groq - Llama-3-70B)            │
├─────────────────────────────────────┤
│ - Intent detection (5 domains)      │
│ - Profile extraction (from speech)  │
│ - Result summarization              │
│ - Form pre-fill reasoning           │
└─────────────────────────────────────┘
                 ↓
┌─────────────────────────────────────┐
│ Embeddings (Sentence-BERT)          │
├─────────────────────────────────────┤
│ - Multilingual (22 Indic languages) │
│ - Unified semantic search           │
│ - Cross-domain matching             │
└─────────────────────────────────────┘
```

### Layer 5: Backend (FastAPI + Router)

```python
# Master request router
@app.post("/api/master/search")
async def unified_search(request: UserQuery):
    """
    Single entry point for all domains.
    Detects intent, routes to modules, combines results.
    """
    
    # Step 1: Intent detection
    intent = detect_intent(request.query_text)  # "welfare|medicine|prices|pollution|disaster"
    
    # Step 2: Route to domain modules
    results = {}
    if "welfare" in intent:
        results["schemes"] = await search_schemes(request.profile)
    if "medicine" in intent:
        results["medicines"] = await search_medicines(request.profile)
    if "prices" in intent:
        results["mandi"] = await search_mandi_prices(request.profile)
    if "pollution" in intent:
        results["aqi_routes"] = await get_safe_routes(request.profile)
    if "disaster" in intent:
        results["alerts"] = await get_disaster_alerts(request.profile)
    
    # Step 3: Combine & rank by relevance
    combined = combine_results(results, request.profile)
    
    # Step 4: Generate one unified PDF form
    form = generate_unified_form(combined, request.profile)
    
    return {
        "results": combined,
        "form_url": form.url,
        "tts_text": generate_summary(combined, request.profile.language)
    }
```

---

## Frontend Architecture

### Tab Navigation (4 Screens)

```
┌─────────────────────────────────────────────────┐
│ BharatSeva                                      │
├─────────────────────────────────────────────────┤
│ [Home] [Search] [Saved] [Profile]              │
├─────────────────────────────────────────────────┤
│                                                 │
│ If on Home → Intro + "Speak your need"          │
│            → 5 domain quick-pick buttons        │
│                                                 │
│ If on Search → Voice + Results                  │
│     Results cards organized by:                │
│     - Domain tabs (Schemes|Medicine|Prices|...) │
│     - Benefit amount (descending)               │
│     - Relevance score                           │
│                                                 │
│ If on Saved → Bookmarked schemes/medicines/... │
│                                                 │
│ If on Profile → Edit attributes (re-used       │
│     across all domains)                         │
│                                                 │
└─────────────────────────────────────────────────┘
```

### Component Reuse

```
Shared Components (all domains):
├── VoiceInput
│   └── Record → Transcribe → Intent detect
├── ResultCard
│   ├── Title + ministry/organization
│   ├── Benefit amount
│   ├── Match score
│   ├── "Why you qualify"
│   └── Action buttons (Save, Apply, etc)
├── DocumentsList
│   └── Required docs badge
├── LocationFinder
│   └── Nearby CSC / Jan Aushadhi / Mandi
└── FormGenerator
    └── PDF with pre-filled fields

Domain-Specific Components:
├── SchemeCard (YojanaMitra)
├── MedicineComparison (AushadhSathi)
├── PriceChart (Annapurna)
├── RouteMap (VayuMitra)
└── AlertCard (PathSetu)
```

---

## Data Flow: Multi-Domain Example

**User:** "Widow, 2 kids, pregnant, wants cheap medicine"

```
[Input] "Vidhva hoon, 2 bachche hain, pregnant hoon, dawa sasta chahiye"
     ↓
[Intent Detection] → ["welfare", "medicine", "prices"]
     ↓
[Profile Extraction]
{
  "marital_status": "widow",
  "family_size": 3,
  "health_conditions": ["pregnancy"],
  "goal": "affordable_medicine"
}
     ↓
[YojanaMitra Module]
→ Query: widow + pregnant + 2 kids
→ Results: [PM Matru Vandana ₹5000, Widow Pension ₹1500, PMJAY]
     ↓
[AushadhSathi Module]
→ Query: prenatal vitamins + low cost
→ Results: [Jan Aushadhi prenatal ₹50, Brand alternative ₹500]
     ↓
[Annapurna Module]
→ Query: nutrition for pregnant widow
→ Results: [Green leafy vegetables ₹20/kg, Pulses ₹80/kg]
     ↓
[Combine Results]
{
  "schemes": [Matru Vandana, Widow Pension],
  "medicines": [Jan Aushadhi prenatal],
  "mandi_prices": [leafy veg, pulses],
  "total_benefit": "₹7500 + ₹450 medicine saving + nutrition plan"
}
     ↓
[Generate Unified PDF Form]
- Application for PM Matru Vandana
- Jan Aushadhi referral
- Nearest CSC for all 3
     ↓
[TTS Output] "Aap 2 schemes ke liye eligible hain. Medicine ₹450 sasta hai. 
              Yeh dekhen. Form ready hai."
```

---

## 6-Week Development Roadmap (Unified)

| Week | Task | Deliverable |
|------|------|-------------|
| **1** | Data integration (5 domains) | Scrape myScheme + Jan Aushadhi + Agmarknet, unified schemes_data.json with 5 categories |
| **2** | Unified backend architecture | FastAPI router, domain modules, intent detection, master /api/master/search endpoint |
| **3** | Vector DB + Intent classifier | Chroma with embeddings for all 5 domains, LLM-based multi-class intent detection |
| **4** | Unified frontend + navigation | Tab-based UI, cross-domain result cards, saved items across domains |
| **5** | Unified form generation + CSC/location finder | Single PDF with fields from all domains, location finder for CSCs/Jan Aushadhi/Mandi/AQI routes/Flood zones |
| **6** | Testing + deployment | E2E testing (20 multi-domain scenarios), user testing with 5+ people, deploy to Railway + Vercel |

---

## Tech Stack (Unified)

```
Same as YojanaMitra + domain-specific APIs:

Core Infrastructure:
├── FastAPI (backend router)
├── Next.js 14 (frontend with tabs)
├── Chroma (vector DB - 5 domains)
├── Groq (LLM inference - intent + summarization)
├── Bhashini (voice - ASR/TTS)

Domain APIs:
├── YojanaMitra: myScheme.gov.in
├── AushadhSathi: Jan Aushadhi API + CDSCO
├── Annapurna: Agmarknet + IMD weather
├── VayuMitra: CPCB AQI + Bhuvan maps
└── PathSetu: CWC flood + IMD weather + Twilio SMS

Free Tiers: ₹0/month (same as before)
```

---

## Success Metrics (Unified)

- [ ] Voice input in 3 languages
- [ ] 1000+ schemes + 5000+ medicines + 50+ crop prices in vector DB
- [ ] Intent detection > 90% accuracy (5 classes)
- [ ] Multi-domain search < 3 seconds
- [ ] Form auto-fill > 70% (fields from multiple domains)
- [ ] Mobile responsive (works on 320px)
- [ ] Tested with 5+ real users across all domains
- [ ] Deployed (Railway + Vercel)

---

## How This Differs from Standalone Apps

| Feature | Standalone (5 Apps) | Unified (1 App) |
|---------|-------------------|-----------------|
| User downloads | 5 apps | 1 app |
| Setup time | 5×3 hrs = 15 hrs | 1×3 hrs = 3 hrs |
| Data management | 5 databases | 1 unified vector DB |
| Voice | Separate per app | One voice gateway |
| Forms | 5 PDFs | One unified multi-domain PDF |
| Developer effort | 5× code | -60% code (reuse) |
| User learning curve | 5 interfaces | 1 interface, 5 domains |

---

## Pitch (Unified)

**"BharatSeva: One Voice. Five Problems. Solved."**

*Problem:* 40% welfare unclaimed + medicine overpriced + farmers lose money + urban AQI kills + rural floods kill

*Solution:* Single voice-first app. User speaks once → gets matches across welfare + medicine + mandi + pollution + disaster

*Tech:* Bhashini (voice) + Groq (LLM) + 5 govt APIs + RAG (vector DB)

*Impact:* One user → 2 hours saved + ₹5000+ saved/year across all domains

*Unique:* First unified voice-first app using ALL govt free APIs end-to-end

---

**Ready to build the unified backend and frontend?**
