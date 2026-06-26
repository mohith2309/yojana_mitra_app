## 2024-05-18 - [Information Leakage in Upstream API Errors]
**Vulnerability:** Raw upstream API errors (including potentially sensitive architectural details or stack traces) were being leaked directly to the client via `HTTPException` detail.
**Learning:** Returning `response.text` from upstream failures in FastAPI endpoints is dangerous as it breaks the principle of failing securely.
**Prevention:** Always log detailed HTTP errors on the server side using a standard logging mechanism and return sanitized, generic error messages (e.g., "Upstream API error") to the client.
