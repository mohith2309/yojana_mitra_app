"""
YojanaMitra Backend API
Voice-first welfare scheme assistant for Indian citizens
"""

from fastapi import FastAPI, UploadFile, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import json
import os
from datetime import datetime
import httpx
import logging

# Vector DB & RAG
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.vectorstores import Chroma
from langchain.embeddings import HuggingFaceEmbeddings
from langchain.llms import Groq
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate

# Models & classifiers
from sklearn.ensemble import RandomForestClassifier
import numpy as np
import pickle

# Utilities
import requests
from dotenv import load_dotenv
import uuid

load_dotenv()

# ────────────────────────────────────────────────────────
# Initialize FastAPI
# ────────────────────────────────────────────────────────

app = FastAPI(
    title="YojanaMitra API",
    description="Voice-first AI welfare scheme assistant",
    version="1.0.0"
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

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")  # Free tier signup
BHASHINI_API_KEY = os.getenv("BHASHINI_API_KEY", "")
API_SETU_CLIENT_ID = os.getenv("API_SETU_CLIENT_ID", "")
API_SETU_SECRET = os.getenv("API_SETU_SECRET", "")

SCHEMES_JSON_PATH = "schemes_data.json"  # Scraped from myScheme
CHROMA_DB_PATH = "./chroma_db"

# ────────────────────────────────────────────────────────
# Data Models
# ────────────────────────────────────────────────────────

class UserProfile(BaseModel):
    name: str
    age: int
    gender: str  # M/F/O
    state: str
    district: Optional[str] = None
    occupation: str
    family_size: int
    annual_income: int
    marital_status: str  # married, widow, divorced, single
    assets: Dict[str, Any] = {}
    languages: List[str] = ["en", "hi"]
    phone: Optional[str] = None

class SchemeMatch(BaseModel):
    scheme_id: str
    scheme_name: str
    ministry: str
    benefit_amount: float
    benefit_frequency: str
    match_score: float
    match_reasons: List[str]
    documents_needed: List[str]
    next_steps: List[str]
    nearest_csc: Optional[Dict] = None

class VoiceRequest(BaseModel):
    audio_base64: str
    language: str = "hi"
    duration_sec: int

class SchemeSearchRequest(BaseModel):
    user_profile: UserProfile
    query: Optional[str] = None  # For text fallback

# ────────────────────────────────────────────────────────
# Initialize RAG Pipeline
# ────────────────────────────────────────────────────────

def load_schemes():
    """Load schemes from JSON and create vector DB"""
    try:
        with open(SCHEMES_JSON_PATH, "r") as f:
            schemes = json.load(f)
    except FileNotFoundError:
        logger.warning(f"{SCHEMES_JSON_PATH} not found, using mock data")
        schemes = load_mock_schemes()

    return schemes

def load_mock_schemes():
    """Return sample schemes for demo"""
    return [
        {
            "id": "pm-matru-vandana",
            "name": "PM Matru Vandana Yojana",
            "ministry": "MWCD",
            "category": "maternal-health",
            "benefit": 5000,
            "benefit_frequency": "quarterly",
            "benefit_total": 15000,
            "description": "Cash assistance to pregnant women for nutrition",
            "eligibility": {
                "pregnant_women_only": True,
                "documents_required": ["Aadhaar", "Delivery cert", "Bank account"]
            },
            "keywords": ["maternity", "pregnancy", "women", "cash"]
        },
        {
            "id": "widow-pension",
            "name": "Widow Pension Support",
            "ministry": "State Social Welfare",
            "category": "social-security",
            "benefit": 1500,
            "benefit_frequency": "monthly",
            "benefit_total": 18000,
            "description": "Monthly pension for eligible widows",
            "eligibility": {
                "widow": True,
                "income_limit": 50000,
                "documents_required": ["Aadhaar", "Death cert", "Income cert"]
            },
            "keywords": ["widow", "pension", "social", "support"]
        },
        {
            "id": "pm-kisan",
            "name": "PM-KISAN",
            "ministry": "Agriculture",
            "category": "farmer-income",
            "benefit": 6000,
            "benefit_frequency": "yearly",
            "benefit_total": 6000,
            "description": "Direct income support to farmers",
            "eligibility": {
                "farmer": True,
                "land_limit_ha": 2,
                "documents_required": ["Aadhaar", "Land record", "Bank account"]
            },
            "keywords": ["farmer", "kisan", "agriculture", "land"]
        }
    ]

def initialize_vector_db():
    """Create Chroma vector DB from schemes"""
    schemes = load_schemes()

    # Prepare documents
    texts = []
    for scheme in schemes:
        text = f"{scheme['name']}. {scheme['description']}. Keywords: {', '.join(scheme.get('keywords', []))}"
        texts.append(text)

    # Create embeddings
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

    return vector_db, schemes

# Initialize on startup
vector_db = None
schemes_data = None

@app.on_event("startup")
async def startup():
    global vector_db, schemes_data
    logger.info("Initializing YojanaMitra...")
    vector_db, schemes_data = initialize_vector_db()
    logger.info(f"Loaded {len(schemes_data)} schemes")

# ────────────────────────────────────────────────────────
# API Endpoints
# ────────────────────────────────────────────────────────

@app.get("/health")
def health():
    return {
        "status": "ok",
        "service": "YojanaMitra API",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.post("/api/voice/transcribe")
async def transcribe_voice(request: VoiceRequest):
    """
    Transcribe audio using Bhashini ASR
    """
    try:
        # Call Bhashini ASR API
        headers = {
            "Authorization": f"Bearer {BHASHINI_API_KEY}",
            "Content-Type": "application/json"
        }

        payload = {
            "audio": request.audio_base64,
            "language": request.language,
            "format": "webm"
        }

        response = httpx.post(
            "https://api.bhashini.gov.in/v1/audio/transcribe",
            json=payload,
            headers=headers,
            timeout=30
        )

        if response.status_code == 200:
            result = response.json()
            return {
                "text": result.get("text", ""),
                "confidence": result.get("confidence", 0.85),
                "language": request.language
            }
        else:
            return {
                "text": "[Bhashini ASR unavailable, fallback to text input]",
                "confidence": 0,
                "language": request.language
            }

    except Exception as e:
        logger.error(f"ASR error: {e}")
        return {"text": "", "confidence": 0, "language": request.language}

@app.post("/api/schemes/search")
async def search_schemes(request: SchemeSearchRequest) -> List[SchemeMatch]:
    """
    Find matching schemes based on user profile
    """
    if not vector_db or not schemes_data:
        raise HTTPException(status_code=503, detail="Service initializing")

    try:
        # Build eligibility query from profile
        profile = request.user_profile
        query = f"""
        Find government welfare schemes for:
        - {profile.age} year old {profile.gender}
        - Occupation: {profile.occupation}
        - Family size: {profile.family_size}
        - Annual income: ₹{profile.annual_income}
        - Marital status: {profile.marital_status}
        - State: {profile.state}

        Return schemes this person is eligible for.
        """

        # RAG retrieval
        docs = vector_db.similarity_search(query, k=10)

        # Eligibility scoring (mock classifier)
        matches = []
        for doc in docs:
            scheme = next(
                (s for s in schemes_data if s['name'] in doc.page_content),
                None
            )
            if not scheme:
                continue

            # Calculate match score (0-1)
            score = calculate_eligibility_score(profile, scheme)
            if score > 0.6:
                match = SchemeMatch(
                    scheme_id=scheme["id"],
                    scheme_name=scheme["name"],
                    ministry=scheme.get("ministry", ""),
                    benefit_amount=scheme.get("benefit", 0),
                    benefit_frequency=scheme.get("benefit_frequency", "one-time"),
                    match_score=score,
                    match_reasons=get_match_reasons(profile, scheme),
                    documents_needed=scheme.get("eligibility", {}).get("documents_required", []),
                    next_steps=get_next_steps(scheme)
                )
                matches.append(match)

        # Sort by benefit amount (highest first)
        matches.sort(
            key=lambda x: x.benefit_amount * (12 if x.benefit_frequency == "monthly" else 1),
            reverse=True
        )

        return matches[:5]  # Return top 5

    except Exception as e:
        logger.error(f"Search error: {e}")
        return []

@app.post("/api/form/generate")
async def generate_application_form(
    scheme_id: str,
    user_data: Dict[str, Any]
):
    """
    Generate pre-filled PDF application form for a scheme
    """
    try:
        scheme = next(
            (s for s in schemes_data if s["id"] == scheme_id),
            None
        )
        if not scheme:
            raise HTTPException(status_code=404, detail="Scheme not found")

        # Jinja2 template rendering
        form_data = {
            "scheme": scheme,
            "applicant": user_data,
            "date": datetime.now().strftime("%d-%m-%Y")
        }

        # TODO: Render Jinja2 template, generate PDF
        return {
            "status": "success",
            "form_url": f"/forms/{scheme_id}_{user_data.get('name', 'applicant')}.pdf",
            "pre_filled_fields": list(user_data.keys())
        }

    except Exception as e:
        logger.error(f"Form generation error: {e}")
        return {"status": "error", "message": str(e)}

@app.post("/api/tts/speak")
async def text_to_speech(text: str, language: str = "hi"):
    """
    Convert text to speech using Bhashini TTS
    """
    try:
        headers = {
            "Authorization": f"Bearer {BHASHINI_API_KEY}",
            "Content-Type": "application/json"
        }

        payload = {
            "text": text,
            "language": language,
            "gender": "female"
        }

        response = httpx.post(
            "https://api.bhashini.gov.in/v1/audio/tts",
            json=payload,
            headers=headers,
            timeout=30
        )

        if response.status_code == 200:
            result = response.json()
            return {
                "audio_base64": result.get("audio", ""),
                "language": language
            }
        else:
            return {"audio_base64": "", "language": language}

    except Exception as e:
        logger.error(f"TTS error: {e}")
        return {"audio_base64": "", "language": language}

@app.get("/api/location/nearby-csc")
async def find_nearby_csc(lat: float, lng: float, radius_km: int = 5):
    """
    Find nearby CSCs for application submission
    """
    # TODO: Query CSC database (400k+ locations)
    return {
        "csc_centers": [
            {
                "name": "Ramgarh CSC",
                "lat": lat + 0.01,
                "lng": lng + 0.01,
                "distance_km": 3.2,
                "address": "Gram Panchayat, Ramgarh, UP",
                "phone": "+91-9876543210",
                "hours": "10 AM - 5 PM"
            }
        ]
    }

# ────────────────────────────────────────────────────────
# Helper Functions
# ────────────────────────────────────────────────────────

def calculate_eligibility_score(profile: UserProfile, scheme: Dict) -> float:
    """
    Calculate eligibility score (0-1) for a user-scheme pair
    """
    score = 0.0
    weights = {
        "occupation": 0.3,
        "income": 0.25,
        "age": 0.2,
        "state": 0.15,
        "family_size": 0.1
    }

    # Occupation match
    scheme_keywords = scheme.get("keywords", [])
    if profile.occupation.lower() in " ".join(scheme_keywords).lower():
        score += weights["occupation"]

    # Income eligibility
    income_limit = scheme.get("eligibility", {}).get("income_limit")
    if not income_limit or profile.annual_income <= income_limit:
        score += weights["income"]

    # Age check
    min_age = scheme.get("eligibility", {}).get("min_age", 0)
    max_age = scheme.get("eligibility", {}).get("max_age", 100)
    if min_age <= profile.age <= max_age:
        score += weights["age"]

    # State variation check
    state_schemes = scheme.get("state_variations", {})
    if profile.state.lower() in state_schemes or "all_states" in state_schemes:
        score += weights["state"] * 0.5

    return min(score, 1.0)

def get_match_reasons(profile: UserProfile, scheme: Dict) -> List[str]:
    """
    Generate human-readable reasons for scheme match
    """
    reasons = []

    if "widow" in " ".join(scheme.get("keywords", [])).lower() and profile.marital_status == "widow":
        reasons.append("Marital status matches (widow)")

    if "farmer" in " ".join(scheme.get("keywords", [])).lower() and profile.occupation.lower() == "farmer":
        reasons.append("Occupation matches (farmer)")

    if profile.family_size <= 3 and "family" in " ".join(scheme.get("keywords", [])).lower():
        reasons.append("Family size eligible")

    return reasons or ["Eligibility criteria met"]

def get_next_steps(scheme: Dict) -> List[str]:
    """
    Generate next steps for application
    """
    docs = scheme.get("eligibility", {}).get("documents_required", [])
    steps = [f"Collect: {', '.join(docs)}" if docs else "Collect required documents"]
    steps.append("Visit nearest CSC with documents")
    steps.append(f"Apply via {scheme.get('ministry', 'government')} portal")
    steps.append("Track application status online")

    return steps

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
