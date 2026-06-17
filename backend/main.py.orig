import asyncio
import json
import os
import re
from typing import Any
from urllib import parse, request

import httpx
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

load_dotenv()

app = FastAPI(
    title="BharatMitra API Gateway",
    version="0.2.0",
    description="Backend gateway for free/sandbox government, civic, environment, and AI APIs. Do not put API keys in the Flutter APK.",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


class TextRequest(BaseModel):
    text: str = Field(min_length=1)
    language: str = "en-IN"


class ProfileRequest(BaseModel):
    text: str = Field(min_length=1)
    use_nvidia: bool = False
    mode: str = "auto"


class ChatRequest(BaseModel):
    prompt: str = Field(min_length=1)
    model: str | None = None
    mode: str = "auto"
    enable_thinking: bool | None = None
    clear_thinking: bool | None = None
    temperature: float | None = None
    top_p: float | None = None
    max_tokens: int | None = None
    reasoning_effort: str | None = None


class RerankRequest(BaseModel):
    query: str = Field(min_length=1)
    passages: list[str] = Field(min_length=1)
    model: str | None = None


class PiiDetectRequest(BaseModel):
    text: str = Field(min_length=1)
    labels: list[str] = Field(default_factory=list)
    threshold: float = Field(default=0.4, ge=0, le=1)
    chunk_length: int = Field(default=384, ge=64, le=4096)
    overlap: int = Field(default=128, ge=0, le=2048)
    flat_ner: bool = False


class DigilockerMockRequest(BaseModel):
    requested_documents: list[str] = Field(default_factory=list)


class MandiAdviceRequest(BaseModel):
    crop: str = ""
    district: str = ""
    state: str = ""
    expected_quantity_kg: float | None = Field(default=None, ge=0)


class AqiPlanRequest(BaseModel):
    location: str = ""
    aqi: int | None = Field(default=None, ge=0, le=999)
    activities: list[str] = Field(default_factory=list)


class FloodRiskRequest(BaseModel):
    district: str = ""
    state: str = ""
    alert_type: str = ""
    water_level_m: float | None = None
    danger_level_m: float | None = None


class CareerGuideRequest(BaseModel):
    class_or_education: str = ""
    interests: list[str] = Field(default_factory=list)
    family_income: int | None = Field(default=None, ge=0)
    district: str = ""


class CivicReportRequest(BaseModel):
    issue: str = Field(default="", max_length=160)
    location: str = Field(default="", max_length=240)
    landmark: str = Field(default="", max_length=160)
    risk: str = Field(default="", max_length=240)
    state: str = Field(default="", max_length=80)
    pincode: str = Field(default="", max_length=12)


def env(name: str, default: str = "") -> str:
    return os.getenv(name, default).strip()


def clean(value: str | None, default: str) -> str:
    value = (value or "").strip()
    return value if value else default


def records_from_payload(payload: Any) -> list[dict[str, Any]]:
    if isinstance(payload, list):
        return [item for item in payload if isinstance(item, dict)]
    if not isinstance(payload, dict):
        return []
    for key in ("records", "data", "items", "results", "rows", "alerts", "schemes", "courses", "contacts"):
        value = payload.get(key)
        if isinstance(value, list):
            return [item for item in value if isinstance(item, dict)]
    return [payload]


def first_value(record: dict[str, Any], keys: list[str], default: str = "") -> str:
    lowered = {key.lower(): value for key, value in record.items()}
    for key in keys:
        value = lowered.get(key.lower())
        if value is not None and str(value).strip():
            return str(value).strip()
    return default


def first_number(record: dict[str, Any], keys: list[str]) -> float | None:
    value = first_value(record, keys)
    if not value:
        return None
    try:
        return float(str(value).replace(",", ""))
    except ValueError:
        return None


def source_status(source: str, *, configured: bool, ok: bool = False, reason: str = "") -> dict[str, Any]:
    return {
        "source": source,
        "configured": configured,
        "ok": ok,
        "reason": reason,
    }


def live_keys_present() -> bool:
    return any(
        [
            env("NVIDIA_API_KEY"),
            env("DATA_GOV_API_KEY"),
            env("BHASHINI_API_KEY"),
            env("API_SETU_CLIENT_ID") and env("API_SETU_CLIENT_SECRET"),
        ]
    )


def local_nvidia_reply(prompt: str, mode: str) -> dict[str, Any]:
    short_prompt = prompt.strip().replace("\n", " ")[:160]
    return {
        "mode": "local_fallback",
        "model": "local/bharatmitra-mock",
        "content": (
            "Local AI fallback: I can still help without an NVIDIA key. "
            "Use local scheme matching, keep documents ready, and verify final eligibility on the official portal. "
            f"Request noted: {short_prompt}"
        ),
        "reasoning_content": None,
        "requested_mode": mode,
    }


def local_pii_entities(text: str) -> list[dict[str, Any]]:
    patterns = {
        "phone_number": r"\b(?:\+91[-\s]?)?[6-9]\d{9}\b",
        "email": r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b",
        "aadhaar": r"\b\d{4}[ -]?\d{4}[ -]?\d{4}\b",
        "pan": r"\b[A-Z]{5}\d{4}[A-Z]\b",
    }
    entities: list[dict[str, Any]] = []
    for label, pattern in patterns.items():
        for match in re.finditer(pattern, text):
            entities.append(
                {
                    "label": label,
                    "text": match.group(0),
                    "start": match.start(),
                    "end": match.end(),
                    "score": 0.9,
                }
            )
    return entities


def overlap_score(query: str, passage: str) -> float:
    query_terms = set(re.findall(r"[a-z0-9]+", query.lower()))
    passage_terms = set(re.findall(r"[a-z0-9]+", passage.lower()))
    if not query_terms:
        return 0.0
    return len(query_terms & passage_terms) / len(query_terms)


def fetch_json_url_sync(url: str, params: dict[str, Any] | None = None) -> Any:
    clean_params = {
        key: value for key, value in (params or {}).items() if value not in ("", None)
    }
    query = parse.urlencode(clean_params)
    separator = "&" if "?" in url else "?"
    full_url = f"{url}{separator}{query}" if query else url
    req = request.Request(full_url, headers={"User-Agent": "BharatMitra/0.2"})
    with request.urlopen(req, timeout=20) as response:
        return json.loads(response.read().decode("utf-8"))


async def fetch_json_url(url: str, params: dict[str, Any] | None = None) -> Any:
    return await asyncio.to_thread(fetch_json_url_sync, url, params)


async def fetch_feed_records(feed_url: str, params: dict[str, Any], source: str) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    if not feed_url:
        return [], source_status(source, configured=False, reason="feed URL missing")
    try:
        payload = await fetch_json_url(feed_url, params)
        records = records_from_payload(payload)
        return records, source_status(source, configured=True, ok=bool(records), reason="" if records else "no matching records")
    except (OSError, ValueError):
        return [], source_status(source, configured=True, reason="public feed unavailable")


async def fetch_data_gov_records(resource_id: str, params: dict[str, Any], source: str, limit: int = 20) -> tuple[list[dict[str, Any]], dict[str, Any]]:
    if not resource_id:
        return [], source_status(source, configured=False, reason="resource ID missing")
    api_key = env("DATA_GOV_API_KEY")
    if not api_key:
        return [], source_status(source, configured=True, reason="DATA_GOV_API_KEY missing")
    base_url = env("DATA_GOV_BASE_URL", "https://api.data.gov.in")
    query = {"api-key": api_key, "format": "json", "limit": str(limit), **params}
    try:
        payload = await fetch_json_url(f"{base_url.rstrip('/')}/resource/{resource_id}", query)
        records = records_from_payload(payload)
        return records, source_status(source, configured=True, ok=bool(records), reason="" if records else "no matching records")
    except (OSError, ValueError):
        return [], source_status(source, configured=True, reason="data.gov.in unavailable")


def configured_demo_modules() -> dict[str, bool]:
    return {
        "mandi": bool(env("MANDI_FEED_URL") or env("MANDI_DATA_GOV_RESOURCE_ID")),
        "aqi": bool(env("AQI_FEED_URL") or env("AQI_DATA_GOV_RESOURCE_ID")),
        "flood": bool(env("FLOOD_ALERT_FEED_URL") or env("FLOOD_DATA_GOV_RESOURCE_ID") or env("SOIL_MOISTURE_DATA_GOV_RESOURCE_ID")),
        "career": bool(
            env("SCHOLARSHIP_FEED_URL")
            or env("SCHOLARSHIP_DATA_GOV_RESOURCE_ID")
            or env("SKILL_FEED_URL")
            or env("SKILL_DATA_GOV_RESOURCE_ID")
        ),
        "civic": bool(
            env("CIVIC_DIRECTORY_FEED_URL")
            or env("CIVIC_DIRECTORY_DATA_GOV_RESOURCE_ID")
            or env("CIVIC_DIRECTORY_BACKUP_DATA_GOV_RESOURCE_ID")
            or env("LGD_VILLAGES_DATA_GOV_RESOURCE_ID")
            or env("LGD_VILLAGES_PIN_DATA_GOV_RESOURCE_ID")
        ),
    }


def model_for_mode(mode: str, explicit_model: str | None = None) -> str:
    if explicit_model:
        return explicit_model
    normalized = mode.lower().strip()
    if normalized in {"consumer", "fast", "chat"}:
        return env("NVIDIA_CONSUMER_MODEL", "google/gemma-3n-e4b-it")
    if normalized in {"auto", "agent", "smart", "reasoning"}:
        return env("NVIDIA_AUTOTASK_MODEL", env("NVIDIA_REASONING_MODEL", "mistralai/mistral-medium-3.5-128b"))
    if normalized == "safety":
        return env("NVIDIA_SAFETY_MODEL", "meta/llama-guard-4-12b")
    if normalized in {"small", "cheap"}:
        return env("NVIDIA_SMALL_MODEL", "nvidia/nemotron-mini-4b-instruct")
    if normalized in {"vision", "multimodal"}:
        return env("NVIDIA_MULTIMODAL_MODEL", "microsoft/phi-4-multimodal-instruct")
    if normalized in {"embed", "embedding"}:
        return env("NVIDIA_EMBED_MODEL", "nvidia/llama-3_2-nemoretriever-300m-embed-v1")
    if normalized == "pii":
        return env("NVIDIA_PII_MODEL", "nvidia/gliner-pii")
    if normalized == "ocr":
        return env("NVIDIA_OCR_MODEL", "microsoft/phi-4-multimodal-instruct")
    if normalized == "rerank":
        return env("NVIDIA_RERANK_MODEL", "nv-rerank-qa-mistral-4b:1")
    return env("NVIDIA_FALLBACK_MODEL", "mistralai/mistral-large-3-675b-instruct-2512")


def env_float(name: str, default: float) -> float:
    value = env(name)
    return float(value) if value else default


def env_int(name: str, default: int) -> int:
    value = env(name)
    return int(value) if value else default


def local_extract_profile(text: str) -> dict[str, Any]:
    lower = text.lower()
    income_match = list(re.finditer(r"(?:income|annual|rs\.?|around|about)?\s*(\d{4,7})", lower))
    income = int(income_match[-1].group(1)) if income_match else None

    def has_any(words: list[str]) -> bool:
        return any(word in lower for word in words)

    return {
        "state": next(
            (
                state
                for state in [
                    "maharashtra",
                    "uttar pradesh",
                    "bihar",
                    "karnataka",
                    "tamil nadu",
                    "rajasthan",
                    "gujarat",
                    "madhya pradesh",
                    "kerala",
                    "odisha",
                    "west bengal",
                    "telangana",
                    "andhra pradesh",
                ]
                if state in lower
            ),
            None,
        ),
        "rural": has_any(["village", "rural", "gaon", "gram"]),
        "low_income": income <= 120000 if income else has_any(["low income", "poor", "garib", "bpl"]),
        "annual_income": income,
        "farmer": has_any(["farmer", "kisan", "crop", "land", "acre", "agriculture"]),
        "widow": has_any(["widow", "husband passed", "pati nahi", "pati died", "single mother"]),
        "student": has_any(["student", "school", "college", "scholarship", "hostel"]),
        "woman_or_girl": has_any(["woman", "female", "girl", "daughter", "mother", "widow", "mahila"]),
        "disability": has_any(["disabled", "disability", "divyang", "handicap"]),
        "housing_need": has_any(["kutcha", "house", "housing", "pucca", "home"]),
        "lpg_need": has_any(["lpg", "cylinder", "gas", "chulha", "smoke"]),
    }


async def nvidia_chat(
    prompt: str,
    model: str | None = None,
    *,
    mode: str = "auto",
    enable_thinking: bool | None = None,
    clear_thinking: bool | None = None,
    temperature: float | None = None,
    top_p: float | None = None,
    max_tokens: int | None = None,
    reasoning_effort: str | None = None,
) -> dict[str, Any]:
    api_key = env("NVIDIA_API_KEY")
    if not api_key:
        return local_nvidia_reply(prompt, mode)

    base_url = env("NVIDIA_BASE_URL", "https://integrate.api.nvidia.com/v1")
    chosen_model = model_for_mode(mode, model)
    url = f"{base_url.rstrip('/')}/chat/completions"
    enable_thinking = enable_thinking if enable_thinking is not None else env("NVIDIA_ENABLE_THINKING", "true").lower() == "true"
    clear_thinking = clear_thinking if clear_thinking is not None else env("NVIDIA_CLEAR_THINKING", "false").lower() == "true"
    normalized_mode = mode.lower().strip()
    default_temperature = (
        env_float("NVIDIA_CONSUMER_TEMPERATURE", 0.2)
        if normalized_mode == "consumer"
        else env_float("NVIDIA_TEMPERATURE", 0.7)
    )
    default_top_p = env_float("NVIDIA_CONSUMER_TOP_P", 0.7) if normalized_mode == "consumer" else env_float("NVIDIA_TOP_P", 1.0)
    default_max_tokens = env_int("NVIDIA_CONSUMER_MAX_TOKENS", 512) if normalized_mode == "consumer" else env_int("NVIDIA_MAX_TOKENS", 16384)
    if normalized_mode == "safety":
        default_temperature = env_float("NVIDIA_SAFETY_TEMPERATURE", 1.0)
        default_top_p = env_float("NVIDIA_SAFETY_TOP_P", 0.7)
        default_max_tokens = env_int("NVIDIA_SAFETY_MAX_TOKENS", 30)
    elif normalized_mode in {"small", "cheap"}:
        default_temperature = env_float("NVIDIA_SMALL_TEMPERATURE", 0.2)
        default_top_p = env_float("NVIDIA_SMALL_TOP_P", 0.7)
        default_max_tokens = env_int("NVIDIA_SMALL_MAX_TOKENS", 1024)
    elif normalized_mode in {"vision", "multimodal"}:
        default_temperature = env_float("NVIDIA_MULTIMODAL_TEMPERATURE", 0.1)
        default_top_p = env_float("NVIDIA_MULTIMODAL_TOP_P", 0.7)
        default_max_tokens = env_int("NVIDIA_MULTIMODAL_MAX_TOKENS", 512)
    default_reasoning_effort = reasoning_effort or env("NVIDIA_REASONING_EFFORT", "high")
    payload = {
        "model": chosen_model,
        "messages": [
            {"role": "system", "content": "You are BharatMitra, a cautious Indian citizen-service assistant. Return concise, verifiable answers."},
            {"role": "user", "content": prompt},
        ],
        "temperature": temperature if temperature is not None else default_temperature,
        "top_p": top_p if top_p is not None else default_top_p,
        "max_tokens": max_tokens if max_tokens is not None else default_max_tokens,
        "chat_template_kwargs": {
            "enable_thinking": enable_thinking,
            "clear_thinking": clear_thinking,
        },
    }
    if normalized_mode != "consumer" and default_reasoning_effort:
        payload["reasoning_effort"] = default_reasoning_effort
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    async with httpx.AsyncClient(timeout=60) as client:
        response = await client.post(url, headers=headers, json=payload)
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    data = response.json()
    message = data["choices"][0]["message"]
    return {
        "model": chosen_model,
        "content": message.get("content") or "",
        "reasoning_content": message.get("reasoning_content"),
    }


async def nvidia_pii_detect(request: PiiDetectRequest) -> dict[str, Any]:
    api_key = env("NVIDIA_API_KEY")
    if not api_key:
        return {
            "mode": "local_fallback",
            "model": "local/pii-rules",
            "result": {"entities": local_pii_entities(request.text)},
        }

    labels = request.labels or [
        "account_number",
        "city",
        "first_name",
        "last_name",
        "occupation",
        "postcode",
        "state",
        "street_address",
        "swift_bic",
        "time",
        "phone_number",
        "email",
        "aadhaar",
        "pan",
    ]
    base_url = env("NVIDIA_BASE_URL", "https://integrate.api.nvidia.com/v1")
    payload = {
        "model": env("NVIDIA_PII_MODEL", "nvidia/gliner-pii"),
        "messages": [{"role": "user", "content": request.text}],
        "labels": labels,
        "threshold": request.threshold,
        "chunk_length": request.chunk_length,
        "overlap": request.overlap,
        "flat_ner": request.flat_ner,
    }
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    async with httpx.AsyncClient(timeout=60) as client:
        response = await client.post(f"{base_url.rstrip('/')}/chat/completions", headers=headers, json=payload)
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    content = response.json()["choices"][0]["message"].get("content") or "{}"
    try:
        parsed = json.loads(content)
    except ValueError:
        parsed = {"raw": content}
    return {"model": payload["model"], "result": parsed}


async def nvidia_rerank(request: RerankRequest) -> dict[str, Any]:
    api_key = env("NVIDIA_API_KEY")
    if not api_key:
        rankings = [
            {"index": index, "score": overlap_score(request.query, passage), "text": passage}
            for index, passage in enumerate(request.passages)
        ]
        rankings.sort(key=lambda item: item["score"], reverse=True)
        return {
            "mode": "local_fallback",
            "model": "local/word-overlap-rerank",
            "rankings": rankings,
        }

    url = env("NVIDIA_RERANK_URL", "https://ai.api.nvidia.com/v1/retrieval/nvidia/reranking")
    payload = {
        "model": request.model or env("NVIDIA_RERANK_MODEL", "nv-rerank-qa-mistral-4b:1"),
        "query": {"text": request.query},
        "passages": [{"text": passage} for passage in request.passages],
    }
    headers = {"Authorization": f"Bearer {api_key}", "Accept": "application/json"}
    async with httpx.AsyncClient(timeout=60) as client:
        response = await client.post(url, headers=headers, json=payload)
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@app.get("/health")
def health() -> dict[str, Any]:
    return {
        "status": "ok",
        "mode": "live" if live_keys_present() else "local",
        "ok": True,
        "configured": {
            "nvidia": bool(env("NVIDIA_API_KEY")),
            "bhashini": bool(env("BHASHINI_API_KEY")),
            "api_setu": bool(env("API_SETU_CLIENT_ID") and env("API_SETU_CLIENT_SECRET")),
            "data_gov": bool(env("DATA_GOV_API_KEY")),
            "live_modules": configured_demo_modules(),
            "demo_modules": True,
        },
    }


@app.post("/profile/extract")
async def extract_profile(request: ProfileRequest) -> dict[str, Any]:
    if request.use_nvidia:
        prompt = (
            "Extract welfare eligibility attributes from this text. Return JSON only with keys: "
            "state, rural, low_income, annual_income, farmer, widow, student, woman_or_girl, "
            "disability, housing_need, lpg_need. Text: "
            f"{request.text}"
        )
        return {"engine": "nvidia", "mode": request.mode, "result": await nvidia_chat(prompt, mode=request.mode)}
    return {"engine": "local_rules", "profile": local_extract_profile(request.text)}


@app.post("/nvidia/chat")
async def chat(request: ChatRequest) -> dict[str, Any]:
    result = await nvidia_chat(
        request.prompt,
        request.model,
        mode=request.mode,
        enable_thinking=request.enable_thinking,
        clear_thinking=request.clear_thinking,
        temperature=request.temperature,
        top_p=request.top_p,
        max_tokens=request.max_tokens,
        reasoning_effort=request.reasoning_effort,
    )
    return {"mode": request.mode, "answer": result["content"], **result}


@app.post("/nvidia/pii-detect")
async def pii_detect(request: PiiDetectRequest) -> dict[str, Any]:
    return await nvidia_pii_detect(request)


@app.post("/nvidia/rerank")
async def rerank(request: RerankRequest) -> dict[str, Any]:
    return await nvidia_rerank(request)


@app.post("/digilocker/mock-documents")
def digilocker_mock(request: DigilockerMockRequest) -> dict[str, Any]:
    available = {"Aadhaar", "Bank account", "Mobile number", "Ration card"}
    return {
        "mode": "mock",
        "note": "Replace with API Setu/DigiLocker sandbox consent flow after credentials are approved.",
        "documents": [
            {"name": doc, "available": doc in available}
            for doc in request.requested_documents
        ],
    }


def normalize_mandi_prices(records: list[dict[str, Any]]) -> list[dict[str, Any]]:
    prices = []
    for record in records[:10]:
        prices.append(
            {
                "crop": first_value(record, ["commodity", "crop", "Commodity"], "unknown crop"),
                "market": first_value(record, ["market", "mandi", "Market"], "unknown mandi"),
                "district": first_value(record, ["district", "District"], ""),
                "state": first_value(record, ["state", "State"], ""),
                "min_price_rs_per_quintal": first_number(record, ["min_price", "Min_Price", "minPrice"]),
                "max_price_rs_per_quintal": first_number(record, ["max_price", "Max_Price", "maxPrice"]),
                "modal_price_rs_per_quintal": first_number(record, ["modal_price", "Modal_Price", "price", "modalPrice"]),
                "date": first_value(record, ["arrival_date", "Arrival_Date", "date", "updated_at"], ""),
            }
        )
    return prices


def mock_mandi_prices(crop: str, district: str, state: str) -> list[dict[str, Any]]:
    return [
        {
            "crop": crop,
            "market": f"Demo mandi near {district}",
            "district": district,
            "state": state,
            "modal_price_rs_per_quintal": 2200,
            "date": "local demo",
        },
        {
            "crop": crop,
            "market": "Nearby wholesale market",
            "district": district,
            "state": state,
            "modal_price_rs_per_quintal": 2050,
            "date": "local demo",
        },
    ]


@app.post("/mandi/advice")
async def mandi_advice(request: MandiAdviceRequest) -> dict[str, Any]:
    crop = clean(request.crop, "your crop")
    district = clean(request.district, "your nearest mandi")
    state = clean(request.state, "your state")
    params = {
        "crop": request.crop,
        "commodity": request.crop,
        "district": request.district,
        "state": request.state,
        "filters[commodity]": request.crop,
        "filters[district]": request.district,
        "filters[state.keyword]": request.state,
    }
    feed_records, feed_status = await fetch_feed_records(env("MANDI_FEED_URL"), params, "mandi_feed")
    data_records, data_status = await fetch_data_gov_records(env("MANDI_DATA_GOV_RESOURCE_ID"), params, "mandi_data_gov")
    live_prices = normalize_mandi_prices(feed_records or data_records)
    display_prices = live_prices or mock_mandi_prices(crop, district, state)
    best_price = max(
        [price for price in display_prices if price["modal_price_rs_per_quintal"] is not None],
        key=lambda price: price["modal_price_rs_per_quintal"],
        default=None,
    )
    quantity_note = (
        f"Approx quantity noted: {request.expected_quantity_kg:g} kg."
        if request.expected_quantity_kg
        else "Add expected quantity for better transport-cost advice."
    )
    if best_price:
        price_note = (
            f"Best live record: {best_price['market']} shows Rs. {best_price['modal_price_rs_per_quintal']:g}/quintal"
            f" for {best_price['crop']}."
        )
    else:
        price_note = f"Compare {crop} prices in at least two mandis near {district} before selling."
    return {
        "mode": "live" if live_prices else "local_fallback",
        "input": {"crop": crop, "district": district, "state": state},
        "prices": display_prices,
        "advice": [
            price_note,
            "Subtract transport, loading, commission, and waiting cost from the quoted price.",
            "If prices are volatile, consider selling in parts instead of one full lot.",
            quantity_note,
        ],
        "source_status": [feed_status, data_status],
        "fallback_message": "" if live_prices else "Live mandi source is not configured or unavailable, so local advice is shown.",
    }


def band_for_aqi(aqi: int | None) -> tuple[str, str]:
    if aqi is None:
        return "unknown", "Add AQI value or connect a live AQI feed."
    if aqi <= 50:
        return "good", "Normal outdoor activity is usually fine."
    if aqi <= 100:
        return "acceptable", "Prefer lower-traffic routes for long outdoor activity."
    if aqi <= 200:
        return "moderate_to_poor", "Keep heavy outdoor work short and prefer cleaner hours."
    return "very_poor", "Avoid unnecessary heavy outdoor activity and follow official local advisories."


def normalize_aqi(records: list[dict[str, Any]]) -> dict[str, Any] | None:
    for record in records[:10]:
        value = first_number(record, ["aqi", "AQI", "value", "air_quality_index", "pollutant_avg", "avg_value"])
        if value is None:
            continue
        return {
            "aqi": int(value),
            "station": first_value(record, ["station", "station_name", "monitoring_station"], ""),
            "location": first_value(record, ["city", "location", "area", "district"], ""),
            "pollutant": first_value(record, ["dominant_pollutant", "pollutant", "parameter", "pollutant_id"], ""),
            "updated_at": first_value(record, ["last_update", "updated_at", "date"], ""),
        }
    return None


@app.post("/aqi/plan")
async def aqi_plan(request: AqiPlanRequest) -> dict[str, Any]:
    location = clean(request.location, "your area")
    activities = request.activities or ["school run", "outdoor work", "travel"]
    normalized_state = request.location.replace(" ", "_")
    params = {
        "location": request.location,
        "city": request.location,
        "filters[country]": "India",
        "filters[state]": normalized_state,
        "filters[city]": request.location,
    }
    feed_records, feed_status = await fetch_feed_records(env("AQI_FEED_URL"), params, "aqi_feed")
    data_records, data_status = await fetch_data_gov_records(env("AQI_DATA_GOV_RESOURCE_ID"), params, "aqi_data_gov")
    live_reading = normalize_aqi(feed_records or data_records)
    mock_reading = {
        "aqi": request.aqi or 135,
        "station": "Local demo station",
        "location": location,
        "pollutant": "PM2.5",
        "updated_at": "local demo",
    }
    selected_aqi = live_reading["aqi"] if live_reading else mock_reading["aqi"]
    band, guidance = band_for_aqi(selected_aqi)
    return {
        "mode": "live" if live_reading else "local_fallback",
        "location": location,
        "aqi": selected_aqi,
        "reading": live_reading or mock_reading,
        "band": band,
        "guidance": guidance,
        "activity_plan": [f"{activity}: plan with current band '{band}' in mind." for activity in activities],
        "source_status": [feed_status, data_status],
        "fallback_message": "" if live_reading else "Live AQI source is not configured or unavailable, so local AQI input is used.",
    }


def normalize_alerts(records: list[dict[str, Any]]) -> list[dict[str, str]]:
    alerts = []
    for record in records[:10]:
        headline = first_value(record, ["headline", "title", "alert", "warning", "description"], "Official alert")
        alerts.append(
            {
                "headline": headline,
                "severity": first_value(record, ["severity", "level", "color", "alert_level"], "watch"),
                "district": first_value(record, ["district", "area", "location"], ""),
                "state": first_value(record, ["state"], ""),
                "source": first_value(record, ["source", "agency"], "official feed"),
                "updated_at": first_value(record, ["updated_at", "date", "issued_at"], ""),
            }
        )
    return alerts


def normalize_rainfall(records: list[dict[str, Any]], district: str = "") -> list[dict[str, Any]]:
    district_lower = district.lower().strip()
    rainfall = []
    for record in records:
        record_district = first_value(record, ["District", "district", "area", "location"], "")
        if district_lower and record_district.lower() != district_lower:
            continue
        rainfall.append(
            {
                "state": first_value(record, ["State", "state"], ""),
                "district": record_district,
                "date": first_value(record, ["Date", "date", "updated_at"], ""),
                "year": first_value(record, ["Year", "year"], ""),
                "month": first_value(record, ["Month", "month"], ""),
                "avg_rainfall_mm": first_number(record, ["Avg_rainfall", "avg_rainfall", "rainfall", "rainfall_mm"]),
                "agency": first_value(record, ["Agency_name", "agency", "source"], ""),
            }
        )
        if len(rainfall) >= 10:
            break
    return rainfall


def normalize_soil_moisture(records: list[dict[str, Any]], district: str = "") -> list[dict[str, Any]]:
    district_lower = district.lower().strip()
    soil = []
    for record in records:
        record_district = first_value(record, ["District", "district", "area", "location"], "")
        if district_lower and record_district.lower() != district_lower:
            continue
        soil.append(
            {
                "state": first_value(record, ["State", "state"], ""),
                "district": record_district,
                "date": first_value(record, ["Date", "date", "updated_at"], ""),
                "year": first_value(record, ["Year", "year"], ""),
                "month": first_value(record, ["Month", "month"], ""),
                "avg_soil_moisture_15cm": first_number(
                    record,
                    ["Avg_smlvl_at15cm", "avg_smlvl_at15cm", "soil_moisture", "avg_soil_moisture"],
                ),
                "agency": first_value(record, ["Agency_name", "agency", "source"], ""),
            }
        )
        if len(soil) >= 10:
            break
    return soil


@app.post("/flood/risk")
async def flood_risk(request: FloodRiskRequest) -> dict[str, Any]:
    district = clean(request.district, "your district")
    state = clean(request.state, "your state")
    alert = request.alert_type.lower().strip()
    params = {
        "district": request.district,
        "state": request.state,
        "alert_type": request.alert_type,
        "filters[State]": request.state,
        "filters[Year]": env("FLOOD_RAINFALL_YEAR", "2025"),
    }
    feed_records, feed_status = await fetch_feed_records(env("FLOOD_ALERT_FEED_URL"), params, "flood_feed")
    data_records, data_status = await fetch_data_gov_records(env("FLOOD_DATA_GOV_RESOURCE_ID"), params, "flood_data_gov")
    soil_params = {
        "filters[State]": request.state,
        "filters[District]": request.district,
        "filters[Year]": env("SOIL_MOISTURE_YEAR", "2022"),
        "filters[Month]": env("SOIL_MOISTURE_MONTH", "01"),
    }
    soil_records, soil_status = await fetch_data_gov_records(
        env("SOIL_MOISTURE_DATA_GOV_RESOURCE_ID"),
        soil_params,
        "soil_moisture_data_gov",
    )
    alerts = normalize_alerts(feed_records)
    rainfall_records = normalize_rainfall(data_records, request.district)
    soil_moisture_records = normalize_soil_moisture(soil_records, request.district)
    generated_alerts = [
        {
            "headline": f"Rainfall record: {item['avg_rainfall_mm']:g} mm in {item['district']} on {item['date']}",
            "severity": "high" if (item["avg_rainfall_mm"] or 0) >= 64.5 else "watch",
            "district": item["district"],
            "state": item["state"],
            "source": item["agency"] or "rainfall data.gov.in",
            "updated_at": item["date"],
        }
        for item in rainfall_records
        if item["avg_rainfall_mm"] is not None
    ]
    generated_alerts.extend(
        {
            "headline": f"Soil moisture record: {item['avg_soil_moisture_15cm']:g} at 15 cm in {item['district']} on {item['date']}",
            "severity": "watch",
            "district": item["district"],
            "state": item["state"],
            "source": item["agency"] or "soil moisture data.gov.in",
            "updated_at": item["date"],
        }
        for item in soil_moisture_records
        if item["avg_soil_moisture_15cm"] is not None
    )
    alerts = [*alerts, *generated_alerts]
    has_live_flood_data = bool(feed_records or data_records or soil_records)
    level_high = (
        request.water_level_m is not None
        and request.danger_level_m is not None
        and request.water_level_m >= request.danger_level_m
    )
    if not alerts:
        alerts = [
            {
                "headline": f"Local demo watch for {district}: check district and IMD alerts before travel.",
                "severity": "high" if level_high else "watch",
                "district": district,
                "state": state,
                "source": "local demo",
                "updated_at": "local demo",
            }
        ]
    alert_text = " ".join([alert, *[item["headline"].lower() for item in alerts], *[item["severity"].lower() for item in alerts]])
    text_high = any(word in alert_text for word in ["red", "high", "flood", "cyclone", "heavy", "severe"])
    risk = "high" if level_high or text_high else "watch"
    return {
        "mode": "live" if has_live_flood_data else "local_fallback",
        "district": district,
        "state": state,
        "risk": risk,
        "alerts": alerts,
        "rainfall_records": rainfall_records,
        "soil_moisture_records": soil_moisture_records,
        "checklist": [
            "Follow district administration, IMD, CWC, NDMA, and local police alerts.",
            "Keep Aadhaar, bank passbook, ration card, and phone in a waterproof bag.",
            "Charge phone, power bank, and torch before waterlogging worsens.",
            "Avoid crossing flooded roads, bridges, and fast-moving water.",
        ],
        "source_status": [feed_status, data_status, soil_status],
        "fallback_message": "" if has_live_flood_data else "Live disaster source is not configured or unavailable, so local safety checklist is shown.",
    }


def normalize_opportunities(records: list[dict[str, Any]], kind: str) -> list[dict[str, str]]:
    items = []
    for record in records[:8]:
        items.append(
            {
                "type": kind,
                "name": first_value(record, ["name", "title", "scheme_name", "course_name"], f"{kind.title()} option"),
                "provider": first_value(record, ["provider", "department", "agency", "ministry"], ""),
                "eligibility": first_value(record, ["eligibility", "education", "class", "qualification"], ""),
                "deadline": first_value(record, ["deadline", "last_date", "closing_date"], ""),
                "url": first_value(record, ["url", "link", "portal"], ""),
            }
        )
    return items


@app.post("/career/guide")
async def career_guide(request: CareerGuideRequest) -> dict[str, Any]:
    education = clean(request.class_or_education, "current class or education")
    district = clean(request.district, "your district")
    interests = request.interests or ["skills", "jobs", "scholarships"]
    params = {"education": request.class_or_education, "district": request.district, "interests": ",".join(interests)}
    scholarship_feed, scholarship_feed_status = await fetch_feed_records(env("SCHOLARSHIP_FEED_URL"), params, "scholarship_feed")
    scholarship_data, scholarship_data_status = await fetch_data_gov_records(
        env("SCHOLARSHIP_DATA_GOV_RESOURCE_ID"), params, "scholarship_data_gov"
    )
    skill_feed, skill_feed_status = await fetch_feed_records(env("SKILL_FEED_URL"), params, "skill_feed")
    skill_data, skill_data_status = await fetch_data_gov_records(env("SKILL_DATA_GOV_RESOURCE_ID"), params, "skill_data_gov")
    opportunities = [
        *normalize_opportunities(scholarship_feed or scholarship_data, "scholarship"),
        *normalize_opportunities(skill_feed or skill_data, "skill"),
    ]
    live_opportunities = bool(opportunities)
    if not opportunities:
        opportunities = [
            {
                "type": "scholarship",
                "name": "National Scholarship Portal search",
                "provider": "Government portals",
                "eligibility": education,
                "deadline": "check official portal",
                "url": "https://scholarships.gov.in/",
            },
            {
                "type": "skill",
                "name": "Skill India local course search",
                "provider": "Skill India Digital",
                "eligibility": "student or job seeker",
                "deadline": "open demo guidance",
                "url": "https://www.skillindiadigital.gov.in/",
            },
        ]
    scholarship_hint = (
        "Prioritize income-based scholarships and fee support."
        if request.family_income is not None and request.family_income <= 250000
        else "Add family income to check scholarship filters."
    )
    return {
        "mode": "live" if live_opportunities else "local_fallback",
        "profile": {"education": education, "district": district, "interests": interests},
        "opportunities": opportunities,
        "guide": [
            f"Review {len(opportunities)} live opportunity records." if live_opportunities else "Use local guidance until live scholarship/skill feeds are configured.",
            scholarship_hint,
            "Shortlist nearby low-cost courses before choosing paid coaching.",
            "Check NSP, state scholarship portal, ITI, Skill India, and apprenticeship options.",
            f"Build a 30-day plan around: {', '.join(interests[:4])}.",
        ],
        "official_links": [
            {"name": "Skill India Digital", "url": "https://www.skillindiadigital.gov.in/"},
            {"name": "Apprenticeship India", "url": "https://www.apprenticeshipindia.gov.in/"},
            {"name": "National Scholarship Portal", "url": "https://scholarships.gov.in/"},
        ],
        "source_status": [scholarship_feed_status, scholarship_data_status, skill_feed_status, skill_data_status],
        "fallback_message": "" if live_opportunities else "Live scholarship/skill sources are not configured or unavailable, so local guidance is shown.",
    }


def normalize_civic_contacts(records: list[dict[str, Any]]) -> list[dict[str, str]]:
    contacts = []
    for record in records[:8]:
        local_body = first_value(
            record,
            ["localBodyNameEnglish", "local_body_name", "municipality", "ulb", "city", "district"],
            "",
        )
        village = first_value(record, ["villageNameEnglish", "village_name", "village"], "")
        local_type = first_value(record, ["localBodyTypeName", "local_body_type", "type"], "")
        pincode = first_value(record, ["pincode", "pinCode", "pin_code"], "")
        contacts.append(
            {
                "city": local_body or village,
                "ward": first_value(record, ["ward", "zone"], ""),
                "department": local_type or first_value(record, ["department", "office", "category"], "local body office"),
                "phone": first_value(record, ["phone", "helpline", "contact", "mobile"], ""),
                "portal": first_value(record, ["portal", "url", "link"], ""),
                "state": first_value(record, ["stateNameEnglish", "state", "State"], ""),
                "pincode": pincode,
                "local_body_code": first_value(record, ["localBodyCode", "local_body_code"], ""),
                "village": village,
            }
        )
    return contacts


def dedupe_civic_contacts(contacts: list[dict[str, str]]) -> list[dict[str, str]]:
    seen = set()
    unique = []
    for contact in contacts:
        key = (
            contact.get("city", ""),
            contact.get("department", ""),
            contact.get("pincode", ""),
            contact.get("local_body_code", ""),
        )
        if key in seen:
            continue
        seen.add(key)
        unique.append(contact)
        if len(unique) >= 8:
            break
    return unique


@app.post("/civic/report-draft")
async def civic_report_draft(request: CivicReportRequest) -> dict[str, Any]:
    issue = clean(request.issue, "local civic issue")
    location = clean(request.location, "your location")
    landmark = clean(request.landmark, "nearby landmark")
    risk = clean(request.risk, "public inconvenience and safety risk")
    state = clean(request.state, "")
    pincode = clean(request.pincode, "")
    params = {
        "issue": request.issue,
        "location": request.location,
        "filters[stateNameEnglish]": state,
        "filters[pincode]": pincode,
    }
    feed_records, feed_status = await fetch_feed_records(env("CIVIC_DIRECTORY_FEED_URL"), params, "civic_directory_feed")
    local_body_pin_records, local_body_pin_status = await fetch_data_gov_records(
        env("CIVIC_DIRECTORY_DATA_GOV_RESOURCE_ID"), params, "civic_directory_data_gov"
    )
    local_body_records, local_body_status = await fetch_data_gov_records(
        env("CIVIC_DIRECTORY_BACKUP_DATA_GOV_RESOURCE_ID"),
        {"filters[stateNameEnglish]": state},
        "civic_directory_backup_data_gov",
    )
    village_pin_records, village_pin_status = await fetch_data_gov_records(
        env("LGD_VILLAGES_PIN_DATA_GOV_RESOURCE_ID"),
        {"filters[stateNameEnglish]": state},
        "lgd_villages_pin_data_gov",
    )
    village_records, village_status = await fetch_data_gov_records(
        env("LGD_VILLAGES_DATA_GOV_RESOURCE_ID"),
        {"filters[stateNameEnglish]": state},
        "lgd_villages_data_gov",
    )
    contacts = dedupe_civic_contacts(
        [
            *normalize_civic_contacts(feed_records),
            *normalize_civic_contacts(local_body_pin_records),
            *normalize_civic_contacts(local_body_records),
            *normalize_civic_contacts(village_pin_records),
            *normalize_civic_contacts(village_records),
        ]
    )
    live_contacts = bool(contacts)
    if not contacts:
        contacts = [
            {
                "department": "Municipal helpline",
                "name": "Local ward office",
                "phone": "112 / local helpline",
                "portal": "state grievance portal",
                "area": location,
            }
        ]
    draft = (
        f"Subject: Request to fix {issue} at {location}\n\n"
        f"Respected Sir/Madam,\n"
        f"Please inspect and fix {issue} at {location}, near {landmark}. "
        f"This is causing {risk}. Kindly register this complaint, share the complaint number, "
        f"and update the expected resolution date.\n\nThank you."
    )
    return {
        "mode": "live" if live_contacts else "local_fallback",
        "draft": draft,
        "contacts": contacts,
        "attach": ["clear photo", "short video if safe", "landmark", "date and time"],
        "escalation": [
            *[f"{contact['department']} {contact['phone'] or contact['portal']}".strip() for contact in contacts[:3]],
            "ward office",
            "municipal helpline",
            "state grievance portal",
        ],
        "source_status": [
            feed_status,
            local_body_pin_status,
            local_body_status,
            village_pin_status,
            village_status,
        ],
        "fallback_message": "" if live_contacts else "Live civic directory is not configured or unavailable, so local complaint draft is shown.",
    }


@app.get("/data-gov/resource/{resource_id}")
async def data_gov_resource(resource_id: str, limit: int = Query(10, ge=1, le=100)) -> dict[str, Any]:
    api_key = env("DATA_GOV_API_KEY")
    if not api_key:
        return {
            "mode": "local_fallback",
            "resource_id": resource_id,
            "records": [
                {
                    "name": "Local demo record",
                    "note": "DATA_GOV_API_KEY is missing, so BharatMitra returned mock data.",
                }
            ][:limit],
            "source_status": [source_status("data_gov", configured=True, reason="DATA_GOV_API_KEY missing")],
        }
    base_url = env("DATA_GOV_BASE_URL", "https://api.data.gov.in")
    params = {"api-key": api_key, "format": "json", "limit": str(limit)}
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.get(f"{base_url.rstrip('/')}/resource/{resource_id}", params=params)
    if response.status_code >= 400:
        raise HTTPException(status_code=response.status_code, detail=response.text)
    return response.json()


@app.post("/bhashini/asr-placeholder")
def bhashini_asr_placeholder(_: TextRequest) -> dict[str, str]:
    if not env("BHASHINI_API_KEY"):
        return {
            "status": "ok",
            "mode": "local_fallback",
            "transcript": "Local mock transcript. Add Bhashini credentials for live ASR/TTS.",
        }
    return {
        "status": "placeholder",
        "mode": "live",
        "next_step": "Implement Bhashini pipeline call here after confirming your pipeline ID and task sequence.",
    }
