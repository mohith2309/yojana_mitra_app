## 2026-07-01 - Optimizing sequential API requests with asyncio.gather
**Learning:** In FastAPI/asyncio, making sequential external API calls using `await` (N+1 I/O bound pattern) blocks execution and slows down endpoints.
**Action:** Always identify independent external API requests in endpoints and execute them concurrently using `asyncio.gather` to avoid N+1 I/O bottlenecks.
