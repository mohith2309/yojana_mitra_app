## 2024-07-11 - Use asyncio.gather for independent external API calls
**Learning:** The FastAPI backend was making multiple independent external API calls sequentially (N+1 pattern) using await, which increases total latency.
**Action:** Always use `asyncio.gather` when making multiple independent external API calls in FastAPI handlers to execute them concurrently.
