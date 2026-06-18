## 2025-02-14 - Prevent Internal Upstream Errors From Leaking
**Vulnerability:** Upstream backend services (NVIDIA, Data.gov) errors were being directly exposed to clients by passing `response.text` into FastAPI `HTTPException` details, potentially leaking internal architecture, dependencies, or verbose API responses.
**Learning:** Returning raw third-party service errors violates the 'fail securely' principle by unnecessarily exposing internal integration details to external callers.
**Prevention:** Catch upstream API errors server-side using `logging.error()` while raising a generic 502 Bad Gateway response to the client. This hides verbose raw third-party responses from external users while maintaining observability for debugging.
