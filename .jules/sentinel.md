## 2024-06-17 - [Info Leakage via Upstream API Errors]
**Vulnerability:** Upstream HTTP errors (like from NVIDIA APIs or Data.gov) were directly passed to the FastAPI `HTTPException` detail and returned to the client.
**Learning:** This exposes sensitive internal architecture, backend IP ranges, or raw error structures. Additionally, auto-formatting tools like `black` must be used with caution to avoid exceeding the <50 line change limit for security PRs.
**Prevention:** Always catch upstream HTTP errors, log the raw text securely server-side using `logger.error`, and return a sanitized `502 Upstream service error` message to the frontend.
