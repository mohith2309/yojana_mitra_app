# Sentinel Journal - Security Learnings

## 2024-03-24 - Prevent Upstream Error Leakage via FastAPI Exceptions
**Vulnerability:** The FastAPI backend directly raised `HTTPException(detail=response.text)` when an external API (like NVIDIA or data.gov.in) returned an error >= 400. This leaks the upstream service architecture, internal API formats, and potentially sensitive error context to the end user.
**Learning:** Returning `response.text` without sanitization creates a critical information exposure risk.
**Prevention:** Always log the verbose error (`response.text` and status code) server-side using Python's `logging` module, and return a sanitized, generic error message (e.g., "Upstream service error") to the client.
