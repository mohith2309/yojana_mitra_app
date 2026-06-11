## 2024-05-24 - Secure FastAPI Upstream Error Handling
**Vulnerability:** Fast API routes returning raw upstream HTTP response text (`response.text`) directly to users via `HTTPException`.
**Learning:** Returning upstream `response.text` can inadvertently leak sensitive API structures, proxy architectures, or token details to end users.
**Prevention:** Always log the detailed error server-side (`logger.error("Upstream error: %s", response.text)`) and return generic error messages to clients (e.g., "Upstream service error").
