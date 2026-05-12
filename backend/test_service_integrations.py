import os
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parent))
import main  # noqa: E402


class FakeResponse:
    def __init__(self, payload=None, status_code=200, text="") -> None:
        self._payload = payload or {}
        self.status_code = status_code
        self.text = text

    def json(self):
        return self._payload


class RecordingAsyncClient:
    calls = []

    def __init__(self, *args, **kwargs) -> None:
        pass

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc, tb) -> bool:
        return False

    async def post(self, url, headers=None, json=None):
        self.__class__.calls.append({"method": "POST", "url": url, "headers": headers or {}, "json": json or {}})
        if "reranking" in url:
            return FakeResponse({"rankings": [{"index": 0, "logit": 1.0}]})
        if (json or {}).get("model") == "nvidia/gliner-pii":
            return FakeResponse({"choices": [{"message": {"content": "{\"entities\": []}"}}]})
        return FakeResponse({"choices": [{"message": {"content": "ok", "reasoning_content": "thinking"}}]})


class ServiceIntegrationTests(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(main.app)
        RecordingAsyncClient.calls = []

    def test_data_gov_resource_without_key_falls_back(self) -> None:
        with patch.dict(os.environ, {"MANDI_DATA_GOV_RESOURCE_ID": "mandi-resource"}, clear=True):
            response = self.client.post(
                "/mandi/advice",
                json={"crop": "onion", "district": "Nashik", "state": "Maharashtra"},
            )

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["mode"], "local_fallback")
        self.assertIn("DATA_GOV_API_KEY missing", [source["reason"] for source in data["source_status"]])

    def test_mandi_advice_uses_mocked_feed(self) -> None:
        async def fake_fetch_json_url(url, params=None):
            return {
                "records": [
                    {
                        "Commodity": "Onion",
                        "Market": "Lasalgaon",
                        "District": "Nashik",
                        "State": "Maharashtra",
                        "Modal_Price": "2200",
                        "Arrival_Date": "2026-05-01",
                    }
                ]
            }

        with patch.dict(os.environ, {"MANDI_FEED_URL": "https://feeds.test/mandi"}, clear=True):
            with patch.object(main, "fetch_json_url", side_effect=fake_fetch_json_url):
                response = self.client.post(
                    "/mandi/advice",
                    json={"crop": "onion", "district": "Nashik", "state": "Maharashtra"},
                )

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["mode"], "live")
        self.assertEqual(data["prices"][0]["market"], "Lasalgaon")

    def test_aqi_plan_uses_mocked_feed(self) -> None:
        async def fake_fetch_json_url(url, params=None):
            return {"records": [{"city": "Delhi", "station": "Anand Vihar", "aqi": 210, "dominant_pollutant": "PM2.5"}]}

        with patch.dict(os.environ, {"AQI_FEED_URL": "https://feeds.test/aqi"}, clear=True):
            with patch.object(main, "fetch_json_url", side_effect=fake_fetch_json_url):
                response = self.client.post("/aqi/plan", json={"location": "Delhi", "activities": ["school run"]})

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["mode"], "live")
        self.assertEqual(data["aqi"], 210)
        self.assertEqual(data["band"], "very_poor")

    def test_flood_risk_uses_mocked_feed(self) -> None:
        async def fake_fetch_json_url(url, params=None):
            return {"alerts": [{"district": "Patna", "state": "Bihar", "severity": "Red", "headline": "Heavy rain flood warning"}]}

        with patch.dict(os.environ, {"FLOOD_ALERT_FEED_URL": "https://feeds.test/flood"}, clear=True):
            with patch.object(main, "fetch_json_url", side_effect=fake_fetch_json_url):
                response = self.client.post("/flood/risk", json={"district": "Patna", "state": "Bihar"})

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["mode"], "live")
        self.assertEqual(data["risk"], "high")
        self.assertEqual(data["alerts"][0]["severity"], "Red")

    def test_career_guide_uses_mocked_feeds(self) -> None:
        async def fake_fetch_json_url(url, params=None):
            if "skill" in url:
                return {"courses": [{"course_name": "Solar technician", "provider": "Skill India", "qualification": "Class 10"}]}
            return {"schemes": [{"scheme_name": "Post Matric Scholarship", "ministry": "Education", "eligibility": "Class 11+"}]}

        env = {
            "SCHOLARSHIP_FEED_URL": "https://feeds.test/scholarships",
            "SKILL_FEED_URL": "https://feeds.test/skills",
        }
        with patch.dict(os.environ, env, clear=True):
            with patch.object(main, "fetch_json_url", side_effect=fake_fetch_json_url):
                response = self.client.post(
                    "/career/guide",
                    json={"class_or_education": "class 12", "interests": ["solar"], "district": "Pune"},
                )

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["mode"], "live")
        self.assertEqual({item["type"] for item in data["opportunities"]}, {"scholarship", "skill"})

    def test_civic_report_draft_uses_mocked_feed(self) -> None:
        async def fake_fetch_json_url(url, params=None):
            return {"contacts": [{"city": "Pune", "ward": "10", "department": "Roads", "helpline": "1800-000-000"}]}

        with patch.dict(os.environ, {"CIVIC_DIRECTORY_FEED_URL": "https://feeds.test/civic"}, clear=True):
            with patch.object(main, "fetch_json_url", side_effect=fake_fetch_json_url):
                response = self.client.post(
                    "/civic/report-draft",
                    json={"issue": "pothole", "location": "MG Road", "landmark": "bus stop"},
                )

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["mode"], "live")
        self.assertEqual(data["contacts"][0]["department"], "Roads")
        self.assertIn("pothole", data["draft"])

    def test_pii_detect_without_key_returns_local_fallback(self) -> None:
        with patch.dict(os.environ, {}, clear=True):
            response = self.client.post("/nvidia/pii-detect", json={"text": "My phone is 9999999999"})

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["mode"], "local_fallback")
        self.assertEqual(data["model"], "local/pii-rules")
        self.assertIn("result", data)

    def test_rerank_without_key_returns_local_fallback(self) -> None:
        with patch.dict(os.environ, {}, clear=True):
            response = self.client.post(
                "/nvidia/rerank",
                json={"query": "scheme", "passages": ["PM-KISAN supports farmers"]},
            )

        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["mode"], "local_fallback")
        self.assertEqual(data["model"], "local/word-overlap-rerank")
        self.assertIn("rankings", data)

    def test_chat_adds_reasoning_effort_for_non_consumer_modes(self) -> None:
        env = {
            "NVIDIA_API_KEY": "test-key",
            "NVIDIA_BASE_URL": "https://integrate.api.nvidia.com/v1",
            "NVIDIA_AUTOTASK_MODEL": "mistralai/mistral-medium-3.5-128b",
            "NVIDIA_REASONING_EFFORT": "high",
        }
        with patch.dict(os.environ, env, clear=True):
            with patch.object(main.httpx, "AsyncClient", RecordingAsyncClient):
                response = self.client.post("/nvidia/chat", json={"mode": "auto", "prompt": "hello"})

        self.assertEqual(response.status_code, 200)
        payload = RecordingAsyncClient.calls[0]["json"]
        self.assertEqual(payload["model"], "mistralai/mistral-medium-3.5-128b")
        self.assertEqual(payload["reasoning_effort"], "high")

    def test_chat_omits_reasoning_effort_for_consumer_mode(self) -> None:
        env = {
            "NVIDIA_API_KEY": "test-key",
            "NVIDIA_BASE_URL": "https://integrate.api.nvidia.com/v1",
            "NVIDIA_CONSUMER_MODEL": "google/gemma-3n-e4b-it",
            "NVIDIA_REASONING_EFFORT": "high",
        }
        with patch.dict(os.environ, env, clear=True):
            with patch.object(main.httpx, "AsyncClient", RecordingAsyncClient):
                response = self.client.post("/nvidia/chat", json={"mode": "consumer", "prompt": "hello"})

        self.assertEqual(response.status_code, 200)
        payload = RecordingAsyncClient.calls[0]["json"]
        self.assertEqual(payload["model"], "google/gemma-3n-e4b-it")
        self.assertNotIn("reasoning_effort", payload)

    def test_pii_detect_uses_gliner_payload_options(self) -> None:
        env = {
            "NVIDIA_API_KEY": "test-key",
            "NVIDIA_BASE_URL": "https://integrate.api.nvidia.com/v1",
            "NVIDIA_PII_MODEL": "nvidia/gliner-pii",
        }
        body = {
            "text": "My phone is 9999999999",
            "labels": ["phone_number"],
            "threshold": 0.8,
            "chunk_length": 128,
            "overlap": 32,
            "flat_ner": True,
        }
        with patch.dict(os.environ, env, clear=True):
            with patch.object(main.httpx, "AsyncClient", RecordingAsyncClient):
                response = self.client.post("/nvidia/pii-detect", json=body)

        self.assertEqual(response.status_code, 200)
        payload = RecordingAsyncClient.calls[0]["json"]
        self.assertEqual(payload["model"], "nvidia/gliner-pii")
        self.assertEqual(payload["labels"], ["phone_number"])
        self.assertEqual(payload["threshold"], 0.8)
        self.assertEqual(payload["chunk_length"], 128)
        self.assertEqual(payload["overlap"], 32)
        self.assertTrue(payload["flat_ner"])

    def test_rerank_uses_nvidia_retrieval_endpoint(self) -> None:
        env = {
            "NVIDIA_API_KEY": "test-key",
            "NVIDIA_RERANK_MODEL": "nv-rerank-qa-mistral-4b:1",
            "NVIDIA_RERANK_URL": "https://ai.api.nvidia.com/v1/retrieval/nvidia/reranking",
        }
        with patch.dict(os.environ, env, clear=True):
            with patch.object(main.httpx, "AsyncClient", RecordingAsyncClient):
                response = self.client.post(
                    "/nvidia/rerank",
                    json={"query": "scheme", "passages": ["PM-KISAN supports farmers"]},
                )

        self.assertEqual(response.status_code, 200)
        call = RecordingAsyncClient.calls[0]
        self.assertEqual(call["url"], "https://ai.api.nvidia.com/v1/retrieval/nvidia/reranking")
        self.assertNotIn("/chat/completions", call["url"])
        self.assertEqual(call["json"]["model"], "nv-rerank-qa-mistral-4b:1")
        self.assertEqual(call["json"]["query"], {"text": "scheme"})


if __name__ == "__main__":
    unittest.main()
