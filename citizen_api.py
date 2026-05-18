#!/usr/bin/env python3
"""
BharatMitra Citizen API
Real-time data: AQI (CPCB), Mandi prices (Agmarknet), Flood risk, Civic drafts
AI advice powered by NVIDIA NIM (Gemma-4 31B)
Run: uvicorn citizen_api:app --host 0.0.0.0 --port 8001
"""

import json as _json
import os
import subprocess
import requests
from concurrent.futures import ThreadPoolExecutor
from datetime import date
from typing import List, Optional
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import asyncio

# ── Config ────────────────────────────────────────────────
DATA_GOV_KEY   = os.getenv("DATA_GOV_KEY", "579b464db66ec23bdd000001f18a062496a0471962be96a13085378d")
NIM_API_KEY    = os.getenv("NVIDIA_API_KEY", "")
NIM_BASE       = "https://integrate.api.nvidia.com/v1"
NIM_MODEL      = "google/gemma-4-31b-it"

AQI_RESOURCE   = "3b01bcb8-0b14-4abf-b6f2-c1bfd384ba69"
MANDI_RESOURCE = "9ef84268-d588-465a-a308-a864a43d0070"
DATA_GOV_BASE  = "https://api.data.gov.in/resource"

_pool = ThreadPoolExecutor(max_workers=6)

def _data_gov_get(resource_id: str, params: dict) -> dict:
    """Fetch from data.gov.in — tries requests first, falls back to curl."""
    url = f"{DATA_GOV_BASE}/{resource_id}"
    try:
        r = requests.get(url, params=params, timeout=25)
        r.raise_for_status()
        return r.json()
    except Exception:
        # curl fallback (more reliable with data.gov.in SSL quirks)
        from urllib.parse import urlencode
        full_url = f"{url}?{urlencode(params)}"
        out = subprocess.check_output(
            ["curl", "-s", "--max-time", "25", full_url], timeout=28
        )
        return _json.loads(out)

# ── State name mapping (user input → CPCB API format) ────
_STATE_MAP = {
    "andhra pradesh": "Andhra_Pradesh", "arunachal pradesh": "Arunachal_Pradesh",
    "assam": "Assam", "bihar": "Bihar", "chandigarh": "Chandigarh",
    "chhattisgarh": "Chhattisgarh", "delhi": "Delhi", "gujarat": "Gujarat",
    "haryana": "Haryana", "himachal pradesh": "Himachal Pradesh",
    "jammu and kashmir": "Jammu_and_Kashmir", "jharkhand": "Jharkhand",
    "karnataka": "Karnataka", "kerala": "Kerala", "madhya pradesh": "Madhya Pradesh",
    "maharashtra": "Maharashtra", "meghalaya": "Meghalaya", "mizoram": "Mizoram",
    "nagaland": "Nagaland", "odisha": "Odisha", "puducherry": "Puducherry",
    "punjab": "Punjab", "rajasthan": "Rajasthan", "sikkim": "Sikkim",
    "tamil nadu": "TamilNadu", "tamilnadu": "TamilNadu", "telangana": "Telangana",
    "tripura": "Tripura", "uttar pradesh": "Uttar_Pradesh",
    "uttarakhand": "Uttarakhand", "west bengal": "West_Bengal",
}

_HIGH_FLOOD = {"Assam", "Bihar", "Uttar Pradesh", "West Bengal", "Odisha",
               "Kerala", "Andhra Pradesh", "Uttarakhand", "Himachal Pradesh"}
_MED_FLOOD  = {"Maharashtra", "Madhya Pradesh", "Rajasthan", "Gujarat",
               "Jharkhand", "Tripura", "Chhattisgarh", "Telangana"}

# ── FastAPI ───────────────────────────────────────────────
app = FastAPI(title="BharatMitra Citizen API", version="1.0.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

# ── Request models ────────────────────────────────────────
class AqiReq(BaseModel):
    location: str

class MandiReq(BaseModel):
    commodity: str = "Tomato"
    state: str = ""
    district: str = ""

class FloodReq(BaseModel):
    state: str
    district: str = ""

class CivicReq(BaseModel):
    issue: str
    location: str
    description: str = ""

class ChatReq(BaseModel):
    prompt: str
    context: str = ""

# ── NIM helper ────────────────────────────────────────────
def _nim_chat(system_msg: str, user_msg: str) -> str:
    if not NIM_API_KEY:
        return "[Set NVIDIA_API_KEY in .env.local to get AI-powered advice]"
    headers = {"Authorization": f"Bearer {NIM_API_KEY}", "Content-Type": "application/json"}
    payload = {
        "model": NIM_MODEL,
        "messages": [
            {"role": "system", "content": system_msg},
            {"role": "user", "content": user_msg},
        ],
        "max_tokens": 400,
        "temperature": 0.4,
    }
    r = requests.post(f"{NIM_BASE}/chat/completions", headers=headers, json=payload, timeout=20)
    r.raise_for_status()
    return r.json()["choices"][0]["message"]["content"].strip()

# ── AQI (CPCB live data) ──────────────────────────────────
def _aqi_label(v: float) -> str:
    return ("Good" if v <= 50 else "Satisfactory" if v <= 100 else
            "Moderate" if v <= 200 else "Poor" if v <= 300 else
            "Very Poor" if v <= 400 else "Severe")

def _fetch_aqi_data(location: str) -> dict:
    cpcb_state = _STATE_MAP.get(location.lower().strip(),
                                location.replace(" ", "_"))
    params = {
        "api-key": DATA_GOV_KEY, "format": "json", "limit": 100,
        "filters[state]": cpcb_state, "filters[pollutant_id]": "PM2.5",
    }
    records = _data_gov_get(AQI_RESOURCE, params).get("records", [])

    if not records:
        params.pop("filters[state]", None)
        params["limit"] = 30
        records = _data_gov_get(AQI_RESOURCE, params).get("records", [])

    values, stations = [], []
    for rec in records:
        try:
            avg = float(rec.get("avg_value") or rec.get("pollutant_avg") or 0)
            if avg > 0:
                values.append(avg)
                stations.append({
                    "city": rec.get("city", ""),
                    "station": rec.get("station", ""),
                    "pm25_avg": round(avg, 1),
                    "updated": rec.get("last_update", ""),
                })
        except (ValueError, TypeError):
            continue

    aqi = round(sum(values) / len(values), 1) if values else 0.0
    return {"aqi": aqi, "stations": stations[:6], "state": cpcb_state}

@app.post("/aqi/plan")
async def aqi_plan(req: AqiReq):
    loop = asyncio.get_event_loop()
    try:
        data = await loop.run_in_executor(_pool, _fetch_aqi_data, req.location)
    except Exception as e:
        raise HTTPException(502, f"CPCB API error: {e}")

    aqi = data["aqi"]
    label = _aqi_label(aqi) if aqi > 0 else "Unknown"

    if aqi > 0 and NIM_API_KEY:
        plan = await loop.run_in_executor(_pool, _nim_chat,
            "You are BharatMitra, a helpful Indian citizen health assistant. Give short, practical advice in 3-4 bullet points.",
            f"AQI in {req.location} is {aqi} PM2.5 ({label}). Give specific activity advice: school run, outdoor work, evening walk, commute. Mention mask if needed. Keep under 80 words.")
    elif aqi > 0:
        plans = {
            "Good": f"✅ AQI {aqi} — Good. Safe for all activities.",
            "Satisfactory": f"🟡 AQI {aqi} — Satisfactory. Sensitive groups limit prolonged outdoor time.",
            "Moderate": f"🟠 AQI {aqi} — Moderate. Avoid outdoor exercise 10am–4pm. Wear mask if out >30 min.",
            "Poor": f"🔴 AQI {aqi} — Poor. No outdoor exercise. Keep windows closed.",
            "Very Poor": f"🚨 AQI {aqi} — Very Poor. Stay indoors. N95 mask for all trips. Kids stay home.",
            "Severe": f"☠️ AQI {aqi} — SEVERE. Health emergency. No outdoor activity. Seek medical help if breathing issues.",
        }
        plan = plans[label]
    else:
        plan = f"No live AQI data found for {req.location}. Check cpcb.gov.in directly."

    return {
        "aqi": aqi,
        "label": label,
        "activity_plan": plan,
        "stations": data["stations"],
        "source": "CPCB via data.gov.in (live)",
    }

# ── Mandi prices (Agmarknet live data) ───────────────────
def _fetch_mandi_data(commodity: str, state: str, district: str) -> dict:
    params = {
        "api-key": DATA_GOV_KEY, "format": "json", "limit": 50,
        "filters[commodity]": commodity,
    }
    if state:
        params["filters[state.keyword]"] = state
    if district:
        params["filters[district]"] = district

    records = _data_gov_get(MANDI_RESOURCE, params).get("records", [])

    markets = []
    for rec in records:
        try:
            modal = float(rec.get("modal_price") or 0)
            if modal > 0:
                markets.append({
                    "market": rec.get("market", ""),
                    "district": rec.get("district", ""),
                    "state": rec.get("state", ""),
                    "commodity": rec.get("commodity", commodity),
                    "variety": rec.get("variety", ""),
                    "min_price": float(rec.get("min_price") or 0),
                    "max_price": float(rec.get("max_price") or 0),
                    "modal_price": modal,
                    "date": rec.get("arrival_date", ""),
                })
        except (ValueError, TypeError):
            continue

    markets.sort(key=lambda m: m["modal_price"], reverse=True)
    prices = [m["modal_price"] for m in markets]
    avg = round(sum(prices) / len(prices), 1) if prices else 0.0
    return {"markets": markets[:8], "avg": avg, "total": len(markets)}

@app.post("/mandi/advice")
async def mandi_advice(req: MandiReq):
    loop = asyncio.get_event_loop()
    try:
        data = await loop.run_in_executor(_pool, _fetch_mandi_data,
                                          req.commodity, req.state, req.district)
    except Exception as e:
        raise HTTPException(502, f"Agmarknet API error: {e}")

    markets = data["markets"]
    avg = data["avg"]
    best = markets[0] if markets else None

    if not markets:
        guidance = f"No price data for {req.commodity} today in {req.state or 'your region'}. Try tomorrow or check agmarknet.gov.in"
    else:
        guidance = (
            f"Best price: ₹{best['modal_price']:.0f}/quintal at {best['market']}, {best['district']}. "
            f"State average: ₹{avg:.0f}/quintal across {data['total']} markets. "
            f"Range: ₹{min(m['min_price'] for m in markets):.0f}–₹{max(m['max_price'] for m in markets):.0f}."
        )
        if NIM_API_KEY and len(markets) >= 2:
            prices_str = ", ".join(f"{m['market']}:₹{m['modal_price']:.0f}" for m in markets[:5])
            ai_tip = await loop.run_in_executor(_pool, _nim_chat,
                "You are an agricultural advisor for Indian small farmers. Give short, practical selling advice.",
                f"Mandi prices for {req.commodity} today: {prices_str}. Average ₹{avg:.0f}/quintal. "
                f"Should farmer sell today or wait? Any transport/timing advice? Max 50 words.")
            guidance += f"\n\nAI Advice: {ai_tip}"

    return {
        "commodity": req.commodity,
        "guidance": guidance,
        "markets": markets,
        "avg_price": avg,
        "source": "Agmarknet via data.gov.in (live)",
    }

# ── Flood risk ────────────────────────────────────────────
@app.post("/flood/risk")
async def flood_risk(req: FloodReq):
    state = req.state.strip()
    risk = "high" if state in _HIGH_FLOOD else "medium" if state in _MED_FLOOD else "low"

    checklists = {
        "high": (
            "⚠️ HIGH RISK STATE\n"
            "• Monitor CWC FloodWatch: cwc.gov.in\n"
            "• Keep emergency kit: torch, medicines, documents in waterproof bag\n"
            "• Know your nearest evacuation route\n"
            "• Move livestock and grain to higher ground if river rises\n"
            "• NDMA helpline: 1078"
        ),
        "medium": (
            "🟡 MODERATE RISK\n"
            "• Check IMD rainfall: mausam.imd.gov.in\n"
            "• Keep drainage clear around home\n"
            "• Store 3-day emergency food & water\n"
            "• NDMA helpline: 1078"
        ),
        "low": (
            f"✅ LOW RISK — {state}\n"
            "• Normal monsoon precautions apply\n"
            "• Check IMD for heavy rainfall warnings: mausam.imd.gov.in\n"
            "• NDMA helpline: 1078"
        ),
    }

    return {
        "state": state,
        "district": req.district,
        "risk": risk,
        "checklist": checklists[risk],
        "live_data_url": "https://cwc.gov.in",
        "source": "NDMA risk zones + CWC historical data",
    }

# ── Civic complaint draft ─────────────────────────────────
@app.post("/civic/report-draft")
async def civic_report(req: CivicReq):
    today = date.today().strftime("%d %B %Y")
    draft = (
        f"CIVIC COMPLAINT — {today}\n"
        f"Issue: {req.issue}\nLocation: {req.location}\n\n"
        f"To,\nThe Municipal Commissioner / Ward Officer,\n{req.location}\n\n"
        f"Subject: Complaint regarding {req.issue}\n\n"
        f"Respected Sir/Madam,\n\n"
        f"I wish to bring the following issue to your attention:\n\n"
        f"Issue: {req.issue}\nLocation: {req.location}\n"
        + (f"Details: {req.description}\n" if req.description else "")
        + "\nThis is causing inconvenience/hazard to residents. "
        "Please take immediate action.\n\n"
        "Thanking you,\n[Your Name]\n[Phone]\n[Address]\n\n"
        "FILE ONLINE:\n"
        "• pgportal.gov.in (PM Grievance Portal)\n"
        "• CPGRAMS mobile app\n"
        "• Helpline: 1916"
    )
    return {"draft": draft, "portals": ["pgportal.gov.in", "cpgrams.gov.in"]}

# ── General AI chat (NIM) ─────────────────────────────────
@app.post("/nvidia/chat")
async def nvidia_chat(req: ChatReq):
    if not NIM_API_KEY:
        raise HTTPException(503, "NVIDIA_API_KEY not configured in .env.local")
    loop = asyncio.get_event_loop()
    system = (
        "You are Yojana Mitra, a helpful AI assistant for Indian citizens. "
        "You help with welfare schemes, health, farming, and daily life questions. "
        "Be concise, practical, and compassionate. Answer in the same language the user writes in."
    )
    user_msg = f"{req.context}\n\n{req.prompt}".strip() if req.context else req.prompt
    try:
        reply = await loop.run_in_executor(_pool, _nim_chat, system, user_msg)
        return {"reply": reply, "model": NIM_MODEL}
    except requests.RequestException as e:
        raise HTTPException(502, f"NIM API error: {e}")

# ── Health check ──────────────────────────────────────────
@app.get("/health")
async def health():
    return {
        "ok": True,
        "configured": {
            "data_gov": bool(DATA_GOV_KEY),
            "nvidia": bool(NIM_API_KEY),
        },
        "endpoints": ["/aqi/plan", "/mandi/advice", "/flood/risk",
                      "/civic/report-draft", "/nvidia/chat"],
    }

# ── Entry point ───────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8001"))
    print(f"\n=== BharatMitra Citizen API on :{port} ===")
    uvicorn.run(app, host="0.0.0.0", port=port)
