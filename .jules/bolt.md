## 2024-05-14 - FastAPI Sequential I/O Bottlenecks
**Learning:** In the FastAPI backend, endpoints fetching data from multiple external sources (like data.gov.in and rss feeds) often suffered from N+1 sequential I/O wait times because `await` was called sequentially on each task instead of being run concurrently.
**Action:** When adding or refactoring endpoints that gather data from multiple external APIs in `main.py`, always group the fetch calls using `asyncio.gather()` to maximize throughput and minimize request latency.
