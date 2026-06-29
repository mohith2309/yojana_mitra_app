## 2025-02-28 - Information Exposure via Upstream Exceptions
**Vulnerability:** Upstream API error details (like `response.text` from external services like NVIDIA or Data.gov) were being passed directly to the client via `HTTPException(detail=...)`.
**Learning:** Returning raw upstream error messages directly to clients can inadvertently leak sensitive internal architecture details, API key validation errors, or specific configuration setups that should not be public.
**Prevention:** Always catch and log raw upstream errors server-side (using Python's `logging` library), and return a generic, sanitized error message (like "Upstream service error") to the client.
