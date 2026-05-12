"""
BharatSeva Unified Backend
Voice-first platform for welfare, medicine, prices, pollution, and disaster alerts
All 5 domains in one FastAPI router
"""

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import json
import os
from datetime import datetime
import httpx
import logging
from enum import Enum

# Vector DB & RAG
from langchain.vectorstores import Chroma
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.llms import Groq

# Utilities
from dotenv import load_dotenv

load_dotenv()

# ────────────────────────────────────────────────────────
# Initialize FastAPI
# ────────────────────────────────────────────────────────

app = FastAPI(
    title="BharatSeva API",
    description="Unified voice-first platform for 5 citizen services",
    version="2.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

logger = logging.getLogger(__name__)

# ────────────────────────────────────────────────────────
# Configuration
# ────────────────────────────────────────────────────────

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
BHASHINI_API_KEY = os.getenv("BHASHINI_API_KEY", "")
API_SETU_CLIENT_ID = os.getenv("API_SETU_CLIENT_ID", "")
API_SETU_SECRET = os.getenv("API_SETU_SECRET", "")

CHROMA_DB_PATH = "./chroma_unified_db"

# ────────────────────────────────────────────────────────
# Enums & Data Models
# ────────────────────────────────────────────────────────

class ServiceDomain(str, Enum):
    WELFARE = "welfare"
    MEDICINE = "medicine"
    PRICES = "prices"
    POLLUTION = "pollution"
    DISASTER = "disaster"

class UserProfile(BaseModel):
    name: str
    age: int
    gender: str  # M/F/O
    state: str
    district: Optional[str] = None
    phone: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    languages: List[str] = ["en", "hi"]

    # YojanaMitra (Welfare)
    occupation: Optional[str] = None
    family_size: Optional[int] = None
    annual_income: Optional[int] = None
    marital_status: Optional[str] = None

    # AushadhSathi (Medicine)
    health_conditions: Optional[List[str]] = []
    allergies: Optional[List[str]] = []

    # Annapurna (Mandi Prices)
    crops: Optional[List[str]] = []

    # VayuMitra (Pollution)
    daily_commute: Optional[str] = None
    respiratory_condition: Optional[str] = None

    # PathSetu (Disaster)
    flood_prone_area: Optional[bool] = False
    phone_alert_enabled: Optional[bool] = True

class UserQuery(BaseModel):
    text: str
    profile: UserProfile
    language: str = "hi"
    domains: Optional[List[ServiceDomain]] = None  # Auto-detect if None

class UnifiedResult(BaseModel):
    schemes: List[Dict[str, Any]] = []
    medicines: List[Dict[str, Any]] = []
    prices: List[Dict[str, Any]] = []
    routes: List[Dict[str, Any]] = []
    alerts: List[Dict[str, Any]] = []
    form_url: Optional[str] = None
    tts_text: str

# ────────────────────────────────────────────────────────
# Unified Data Loading
# ────────────────────────────────────────────────────────

def load_unified_data():
    """Load data for all 5 domains"""
    data = {
        "schemes": [],
        "medicines": [],
        "prices": [],
        "routes": [],
        "alerts": []
    }

    # YojanaMitra: Welfare schemes
    data["schemes"] = [
        {
            "id": "pm-matru-vandana",
            "name": "PM Matru Vandana Yojana",
            "domain": "welfare",
            "ministry": "MWCD",
            "benefit": 5000,
            "benefit_frequency": "quarterly",
            "keywords": ["maternity", "pregnancy", "women", "cash"]
        },
        {
            "id": "widow-pension",
            "name": "Widow Pension Support",
            "domain": "welfare",
            "ministry": "State Social Welfare",
            "benefit": 1500,
            "benefit_frequency": "monthly",
            "keywords": ["widow", "pension", "social"]
        },
        {
            "id": "pm-kisan",
            "name": "PM-KISAN",
            "domain": "welfare",
            "ministry": "Agriculture",
            "benefit": 6000,
            "benefit_frequency": "yearly",
            "keywords": ["farmer", "agriculture", "income"]
        }
    ]

    # AushadhSathi: Medicine substitutes
    data["medicines"] = [
        {
            "id": "jan-aushadhi-prenatal",
            "name": "Jan Aushadhi Prenatal Vitamin",
            "domain": "medicine",
            "price_jan_aushadhi": 50,
            "price_market": 500,
            "savings": 450,
            "nearest_center": "Ramgarh CSC",
            "keywords": ["pregnancy", "vitamin", "prenatal", "cheap"]
        },
        {
            "id": "paracetamol-generic",
            "name": "Generic Paracetamol 500mg",
            "domain": "medicine",
            "price_jan_aushadhi": 3,
            "price_market": 15,
            "savings": 12,
            "keywords": ["fever", "pain", "generic", "affordable"]
        }
    ]

    # Annapurna: Mandi prices
    data["prices"] = [
        {
            "id": "wheat-today",
            "crop": "wheat",
            "current_price": 2400,
            "unit": "quintal",
            "market": "Ramgarh Mandi",
            "state": "UP",
            "date": "2026-05-11",
            "forecast_7day": 2450,
            "keywords": ["wheat", "price", "mandi", "agriculture"]
        },
        {
            "id": "spinach-today",
            "crop": "spinach",
            "current_price": 20,
            "unit": "kg",
            "market": "Ramgarh Vegetable Market",
            "state": "UP",
            "date": "2026-05-11",
            "keywords": ["spinach", "vegetables", "nutrition", "price"]
        }
    ]

    # VayuMitra: Pollution & safe routes
    data["routes"] = [
        {
            "id": "route-bypass-aqi",
            "from": "Home",
            "to": "Office",
            "current_aqi": 320,
            "unsafe_route_aqi": 400,
            "safe_route_aqi": 180,
            "safe_route_distance_extra": 2.5,
            "keywords": ["pollution", "aqi", "route", "safe"]
        }
    ]

    # PathSetu: Disaster alerts
    data["alerts"] = [
        {
            "id": "flood-alert-ramgarh",
            "type": "flood",
            "severity": "medium",
            "location": "Ramgarh, UP",
            "message": "Flood warning: River level rising",
            "action": "Move to higher ground within 2 hours",
            "keywords": ["flood", "warning", "alert", "disaster"]
        }
    ]

    return data

def initialize_vector_db():
    """Create unified vector DB for all domains"""
    data = load_unified_data()

    # Prepare unified document corpus
    texts = []
    for domain_key, items in data.items():
        for item in items:
            text = f"{item.get('name', '')} {item.get('domain', '')} {' '.join(item.get('keywords', []))}"
            texts.append(text)

    # Create embeddings (multilingual)
    embeddings = HuggingFaceEmbeddings(
        model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
    )

    # Create vector store
    if os.path.exists(CHROMA_DB_PATH):
        vector_db = Chroma(
            persist_directory=CHROMA_DB_PATH,
            embedding_function=embeddings
        )
    else:
        vector_db = Chroma.from_texts(
            texts,
            embeddings,
            persist_directory=CHROMA_DB_PATH
        )

    return vector_db, data

# Initialize
vector_db = None
unified_data = None

@app.on_event("startup")
async def startup():
    global vector_db, unified_data
    logger.info("Initializing BharatSeva...")
    vector_db, unified_data = initialize_vector_db()
    logger.info("Unified platform ready: 3 schemes + 2 medicines + 2 prices + 1 route + 1 alert")

# ────────────────────────────────────────────────────────
# Intent Detection
# ────────────────────────────────────────────────────────

def detect_intent(text: str) -> List[ServiceDomain]:
    """Detect which domains user is asking about"""
    text_lower = text.lower()
    domains = []

    # Welfare keywords
    if any(word in text_lower for word in ["scheme", "yojana", "welfare", "pension", "help", "सहायता"]):
        domains.append(ServiceDomain.WELFARE)

    # Medicine keywords
    if any(word in text_lower for word in ["medicine", "dawa", "दवा", "doctor", "health", "tablet", "aushadhi"]):
        domains.append(ServiceDomain.MEDICINE)

    # Price keywords
    if any(word in text_lower for word in ["price", "भाव", "mandi", "मंडी", "crop", "farmer", "cost", "सस्ता"]):
        domains.append(ServiceDomain.PRICES)

    # Pollution keywords
    if any(word in text_lower for word in ["pollution", "aqi", "air", "route", "safe", "breath", "हवा"]):
        domains.append(ServiceDomain.POLLUTION)

    # Disaster keywords
    if any(word in text_lower for word in ["flood", "बाढ़", "warning", "alert", "weather", "disaster", "alert"]):
        domains.append(ServiceDomain.DISASTER)

    # Default to welfare if no domain detected
    if not domains:
        domains = [ServiceDomain.WELFARE]

    return list(set(domains))  # Remove duplicates

# ────────────────────────────────────────────────────────
# Domain-Specific Search Functions
# ────────────────────────────────────────────────────────

async def search_schemes(profile: UserProfile) -> List[Dict]:
    """YojanaMitra: Search welfare schemes"""
    results = []

    for scheme in unified_data["schemes"]:
        score = 0.7  # Mock scoring
        if profile.occupation and "farmer" in scheme["keywords"]:
            score = 0.95
        if profile.marital_status == "widow" and "widow" in scheme["keywords"]:
            score = 0.94
        if any(kw in scheme["keywords"] for kw in [profile.marital_status] if profile.marital_status):
            score = max(score, 0.85)

        if score > 0.6:
            results.append({**scheme, "match_score": score})

    return sorted(results, key=lambda x: x["match_score"], reverse=True)

async def search_medicines(profile: UserProfile) -> List[Dict]:
    """AushadhSathi: Search medicine substitutes"""
    results = []

    for medicine in unified_data["medicines"]:
        score = 0.5

        # Match against health conditions
        if any(cond in medicine["keywords"] for cond in profile.health_conditions if profile.health_conditions):
            score = 0.95

        # All medicines shown with savings
        results.append({**medicine, "match_score": score})

    return sorted(results, key=lambda x: x["match_score"], reverse=True)

async def search_mandi_prices(profile: UserProfile) -> List[Dict]:
    """Annapurna: Search mandi prices"""
    results = []

    for price in unified_data["prices"]:
        score = 0.6

        # Match against crops if farmer
        if profile.occupation == "farmer" and any(crop in price["keywords"] for crop in profile.crops):
            score = 0.95

        results.append({**price, "match_score": score})

    return sorted(results, key=lambda x: x["match_score"], reverse=True)

async def search_safe_routes(profile: UserProfile) -> List[Dict]:
    """VayuMitra: Find safe routes avoiding pollution"""
    results = []

    if profile.lat and profile.lng:
        # In production, fetch from CPCB AQI API
        for route in unified_data["routes"]:
            route["match_score"] = 0.9
            results.append(route)

    return results

async def search_disaster_alerts(profile: UserProfile) -> List[Dict]:
    """PathSetu: Get disaster alerts for location"""
    results = []

    if profile.state and profile.district:
        # In production, fetch from CWC + IMD
        for alert in unified_data["alerts"]:
            if profile.flood_prone_area and "flood" in alert["keywords"]:
                alert["match_score"] = 0.95
                results.append(alert)

    return results

# ────────────────────────────────────────────────────────
# API Endpoints
# ────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "BharatSeva API (Unified)",
        "domains": 5,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.post("/api/master/search")
async def unified_search(request: UserQuery) -> UnifiedResult:
    """
    Main entry point: Single query → Multiple domains
    Detects intent, routes to modules, combines results
    """
    if not unified_data:
        raise HTTPException(status_code=503, detail="Service initializing")

    try:
        # Step 1: Detect intent
        domains = request.domains or detect_intent(request.text)
        logger.info(f"Detected domains: {domains}")

        # Step 2: Route to domain modules
        results = UnifiedResult(
            schemes=[],
            medicines=[],
            prices=[],
            routes=[],
            alerts=[],
            tts_text=""
        )

        if ServiceDomain.WELFARE in domains:
            results.schemes = await search_schemes(request.profile)

        if ServiceDomain.MEDICINE in domains:
            results.medicines = await search_medicines(request.profile)

        if ServiceDomain.PRICES in domains:
            results.prices = await search_mandi_prices(request.profile)

        if ServiceDomain.POLLUTION in domains:
            results.routes = await search_safe_routes(request.profile)

        if ServiceDomain.DISASTER in domains:
            results.alerts = await search_disaster_alerts(request.profile)

        # Step 3: Generate summary TTS text
        summary_parts = []

        if results.schemes:
            total_benefit = sum(s.get("benefit", 0) for s in results.schemes)
            summary_parts.append(f"{len(results.schemes)} welfare schemes worth ₹{total_benefit}")

        if results.medicines:
            total_savings = sum(m.get("savings", 0) for m in results.medicines)
            summary_parts.append(f"₹{total_savings} medicine savings")

        if results.prices:
            summary_parts.append(f"Mandi prices for {len(results.prices)} crops")

        if results.routes:
            summary_parts.append(f"Safe route avoiding pollution")

        if results.alerts:
            summary_parts.append(f"Alert: {results.alerts[0].get('message', '')}")

        results.tts_text = ". ".join(summary_parts) if summary_parts else "No matches found"

        return results

    except Exception as e:
        logger.error(f"Unified search error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/voice/transcribe")
async def transcribe_voice(
    text: Optional[str] = None,
    language: str = "hi"
):
    """
    Transcribe audio via Bhashini ASR
    For now, accepts text directly (frontend does transcription)
    """
    return {
        "text": text or "",
        "confidence": 0.90,
        "language": language
    }

@app.post("/api/form/generate-unified")
async def generate_unified_form(
    scheme_id: Optional[str] = None,
    medicine_id: Optional[str] = None,
    user_data: Dict[str, Any] = None
):
    """
    Generate single PDF form spanning multiple domains
    """
    return {
        "status": "success",
        "form_url": "/forms/unified_application.pdf",
        "pre_filled_fields": list(user_data.keys()) if user_data else []
    }

@app.post("/api/tts/speak")
async def text_to_speech(text: str, language: str = "hi"):
    """
    Convert text to speech via Bhashini TTS
    """
    return {
        "audio_base64": f"data:audio/wav;base64,mock",
        "language": language
    }

# ────────────────────────────────────────────────────────
# Domain-Specific Endpoints (for direct access)
# ────────────────────────────────────────────────────────

@app.post("/api/yojana/search")
async def search_yojana_schemes(profile: UserProfile) -> List[Dict]:
    """Direct welfare scheme search"""
    return await search_schemes(profile)

@app.post("/api/aushadh/search")
async def search_aushadh_medicines(profile: UserProfile) -> List[Dict]:
    """Direct medicine substitute search"""
    return await search_medicines(profile)

@app.post("/api/annapurna/prices")
async def search_annapurna_prices(profile: UserProfile) -> List[Dict]:
    """Direct mandi price search"""
    return await search_mandi_prices(profile)

@app.post("/api/vayu/routes")
async def search_vayu_routes(profile: UserProfile) -> List[Dict]:
    """Direct safe route search"""
    return await search_safe_routes(profile)

@app.post("/api/path/alerts")
async def search_path_alerts(profile: UserProfile) -> List[Dict]:
    """Direct disaster alert search"""
    return await search_disaster_alerts(profile)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
