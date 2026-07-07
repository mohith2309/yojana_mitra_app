## 2026-07-07 - Concurrent API Requests in FastAPI
**Learning:** Sequential await calls for independent upstream APIs in FastAPI endpoints create significant N+1 I/O bottlenecks.
**Action:** Use asyncio.gather for independent external API calls to execute them concurrently, drastically reducing endpoint response times.
