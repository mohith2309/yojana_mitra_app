## 2025-03-05 - Prevent FastApi Upstream Error Leakage
**Vulnerability:** FastApi endpoints were catching `httpx` downstream errors and raising `HTTPException(status_code, detail=response.text)`, exposing internal infrastructure details and unhandled error responses to external clients.
**Learning:** Returning raw third-party responses is an information disclosure vector.
**Prevention:** Always log `response.text` locally and replace the `detail` parameter with a sanitized generic message (e.g. "Upstream service error").
