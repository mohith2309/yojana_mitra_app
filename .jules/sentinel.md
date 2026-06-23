
## 2024-05-18 - [Prevent Internal Architecture Leakage in FastAPI Exceptions]
**Vulnerability:** Upstream API errors (like `response.text` from Data.gov or NVIDIA APIs) were being directly passed to the client via `HTTPException` detail. This exposes sensitive internal service architecture, exact upstream error messages, and potential infrastructure details to users.
**Learning:** Returning raw upstream API responses to the client breaches the "fail securely" principle by revealing the internal workings and exact dependencies of the backend gateway.
**Prevention:** Instead of returning raw error texts via `HTTPException`, always log verbose errors server-side (e.g., using `logging`) and return a generic, sanitized message (like "Upstream service error" with status 502) to the client.
