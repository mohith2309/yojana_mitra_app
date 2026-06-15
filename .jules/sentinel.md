## 2026-06-15 - [Secure Error Handling]
**Vulnerability:** Fast API routes exposing raw upstream API error responses (`response.text`) to the client via `HTTPException` detail.
**Learning:** This exposes internal service architecture and unhandled errors directly to clients.
**Prevention:** Log verbose errors server-side instead, returning generic, sanitized messages to prevent leakage of internal service architecture.
