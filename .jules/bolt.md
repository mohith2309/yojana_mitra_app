## 2024-05-30 - [Parallelize External API Calls in FastAPI]
**Learning:** Sequential external API calls (N+1 I/O problem) in Python's async endpoints significantly degraded performance. The FastAPI handlers for civic directories, mandi prices, flood risks, and career guides awaited up to 5 independent network requests one by one.
**Action:** Use `asyncio.gather` to execute independent network I/O concurrently. This reduces total waiting time to the latency of the slowest request rather than the sum of all requests, dramatically improving throughput.
