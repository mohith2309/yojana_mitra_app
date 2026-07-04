## 2024-05-14 - [Concurrent External API Calls]
**Learning:** Sequential external API calls (e.g., using multiple `await`s sequentially in endpoints like `civic_report_draft`) create significant latency bottlenecks.
**Action:** Always use `asyncio.gather` to execute independent external API calls concurrently in FastAPI endpoints.
