## 2025-02-28 - Upstream Error Detail Leakage in FastAPI
**Vulnerability:** Upstream error details (`response.text`) from third-party APIs (like NVIDIA, Data.gov) were directly passed into FastAPI `HTTPException` detail fields and sent to the client.
**Learning:** Returning raw upstream error strings to clients exposes internal service infrastructure, third-party error schemas, and potentially sensitive tokens or internal routing details to external users.
**Prevention:** Always log raw third-party errors server-side using a standard logger, and raise a generic HTTP error message (e.g., "Upstream service error") to the client.
