## 2024-06-12 - [Gather independent external API requests]
**Learning:** Making sequential external API requests in the FastAPI backend causes N+1 bottlenecks.
**Action:** Always use `asyncio.gather` when making multiple independent external API requests (e.g., `fetch_feed_records` and `fetch_data_gov_records`) to run them concurrently.
