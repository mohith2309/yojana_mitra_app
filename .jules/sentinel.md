## 2025-06-21 - [Preventing Information Leakage in API Gateways]
**Vulnerability:** Upstream API error details (like `response.text` from `httpx`) were passed directly to clients in FastAPI `HTTPException` detail fields.
**Learning:** Returning raw API responses from upstream services leaks internal architecture, API formats, and potentially sensitive error states to users.
**Prevention:** Always log verbose `response.text` errors server-side using `logging.error()`, and return a sanitized, generic error message (e.g., "Upstream service error") to the client.
