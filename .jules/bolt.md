## 2025-05-18 - Avoid N+1 sequential I/O bottlenecks in FastAPI endpoints using `asyncio.gather`
**Learning:** In the FastAPI backend, sequentially awaiting multiple independent external API calls (e.g., fetching from `fetch_feed_records` and then `fetch_data_gov_records`) creates unnecessary N+1 bottlenecks.
**Action:** When making multiple independent external API calls, always use `asyncio.gather` to execute them concurrently. This pattern should be consistently applied across all data integration points to improve overall latency.
