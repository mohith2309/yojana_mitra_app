## 2026-06-19 - Concurrency for Independent API Calls
**Learning:** Sequential `await` calls to independent external APIs (like Data.gov or RSS feeds) create an N+1 I/O bottleneck, directly compounding response latency. In endpoints with multiple such calls (e.g., `civic_report_draft`), replacing them with `asyncio.gather` dramatically cuts wait time to that of the slowest single request.
**Action:** Default to `asyncio.gather()` when making multiple, non-dependent external API or database calls in an async endpoint.
