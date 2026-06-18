## 2024-06-18 - [Parallelize External API Calls in FastAPI]
**Learning:** Sequential `await` calls for independent external APIs in FastAPI handlers create a massive N+1 I/O bottleneck, significantly increasing endpoint response times (latency equals the sum of all requests).
**Action:** Always group independent `await` calls using `asyncio.gather` to execute them concurrently, reducing total latency to the duration of the single longest request.
