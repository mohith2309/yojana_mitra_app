## 2024-05-18 - Concurrent API fetching in FastAPI endpoints
**Learning:** The FastAPI endpoints in this codebase often aggregate data from multiple independent sources (e.g., Data.gov.in and feed APIs), leading to sequential N+1 I/O bottlenecks where endpoints block on `await` sequentially.
**Action:** Always use `asyncio.gather` for independent `fetch_data_gov_records` and `fetch_feed_records` calls to reduce latency by making them concurrent.
