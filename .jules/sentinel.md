## 2024-05-18 - Prevent Sensitive Data Leakage in HTTPException Details
**Vulnerability:** The FastAPI backend directly forwarded raw `response.text` from upstream HTTP failures to the client via `HTTPException(detail=...)`.
**Learning:** This exposes the architecture of downstream services (like NVIDIA and Data.gov.in) and risks leaking specific error messages or constraints back to the end user.
**Prevention:** Implement a standard logging strategy to record exact upstream failures server-side, and return a sanitized `502 Upstream service error` directly to the client.
