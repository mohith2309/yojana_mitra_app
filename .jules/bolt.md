## 2025-05-24 - N+1 Bottleneck in Async Backend Endpoints
**Learning:** Multiple endpoints in the backend (e.g., civic_report_draft, mandi_advice, aqi_plan) were executing independent external API calls sequentially using `await`, causing severe N+1 I/O bottlenecks.
**Action:** Always wrap independent asynchronous tasks with `asyncio.gather` to execute them concurrently when building FastApi backend logic, especially for data aggregation endpoints.
