## 2025-05-15 - Backend sequential I/O bottleneck
**Learning:** In the FastAPI backend (`backend/main.py`), endpoints like `/flood/risk`, `/civic/report-draft`, etc., sequentially awaited external feeds (`fetch_feed_records` and `fetch_data_gov_records`). This created a significant N+1 I/O blocking problem, where total latency equals the sum of all individual HTTP roundtrips.
**Action:** Used `asyncio.gather` to execute these remote fetches concurrently, converting O(N) latency into O(1) latency relative to external request times.
