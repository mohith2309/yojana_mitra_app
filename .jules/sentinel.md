## 2025-02-27 - Upstream API Error Leakage
**Vulnerability:** The FastAPI backend directly returned raw upstream API error responses (e.g. from NVIDIA and data.gov.in) to the client by passing `response.text` into the `detail` parameter of `HTTPException`.
**Learning:** This exposes internal service architecture and could leak sensitive information such as tokens or stack traces to malicious users.
**Prevention:** Avoid passing raw upstream API error responses to the client. Instead, log verbose errors server-side and return generic, sanitized messages to prevent leakage of internal service architecture.
