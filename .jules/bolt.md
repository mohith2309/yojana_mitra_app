## 2024-07-09 - [Concurrency in I/O Bound FastAPI endpoints]
**Learning:** Sequential awaits on independent external API calls (N+1 anti-pattern) create significant performance bottlenecks in FastAPI endpoints aggregating multiple data sources.
**Action:** Always wrap independent `await` tasks (like `fetch_feed_records` and `fetch_data_gov_records`) in `asyncio.gather()` when pulling from multiple downstream APIs.
