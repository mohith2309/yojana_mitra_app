## 2024-07-12 - Concurrent API Fetches
**Learning:** FastAPI endpoints making multiple independent external API calls sequentially (like `civic_report_draft` fetching 5 feeds) create massive I/O bottlenecks.
**Action:** Always use `asyncio.gather` to execute independent external API fetches concurrently.
