## 2024-06-25 - Use asyncio.gather for Independent External API Calls
**Learning:** In FastAPI, sequential `await` calls for independent external APIs create an N+1 I/O bottleneck, meaning the total request time becomes the sum of all individual response times.
**Action:** Always use `asyncio.gather` when making multiple independent external API calls concurrently to reduce total latency.
