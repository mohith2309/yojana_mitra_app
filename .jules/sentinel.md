## 2024-05-20 - Prevent Information Disclosure in API Errors
**Vulnerability:** Upstream API error details (response.text) were passed directly to the client via FastAPI's HTTPException.
**Learning:** Exposing raw error responses from external APIs can leak internal service architecture, tokens, or infrastructure details to malicious users.
**Prevention:** Always log verbose errors server-side for debugging and return generic, sanitized error messages to the client.
