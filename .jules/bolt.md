## 2024-06-13 - [FastAPI Concurrent I/O Optimization]
**Learning:** In the FastAPI backend, making sequential independent external API calls (using `await fetch_feed_records` and `await fetch_data_gov_records` in series) causes an N+1 I/O bottleneck that severely delays endpoint responses.
**Action:** Always use `asyncio.gather` when making multiple independent external API calls to execute them concurrently and reduce overall response times.
