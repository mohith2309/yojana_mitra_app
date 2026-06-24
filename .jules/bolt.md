## 2025-05-18 - [Fix N+1 sequential I/O bottleneck in external API calls]
**Learning:** Found a severe N+1 API bottleneck in `civic_report_draft` because it makes 5 sequential external API calls (fetching feeds and data.gov resources) before aggregating results. This is common when adding backup or fallback sources incrementally.
**Action:** Always use `asyncio.gather` in FastAPI when making multiple independent external API requests (e.g. data feeds, backup sources) to execute them concurrently instead of sequentially.
