## 2024-06-28 - Secure Error Handling

**Vulnerability:** Upstream API error details (like full internal response text) were directly leaked to clients via `HTTPException` responses in `backend/main.py`. This exposes internal service architecture or potentially sensitive information.
**Learning:** Returning `response.text` directly in an HTTPException leaks too much information to the user when wrapping external APIs.
**Prevention:** Always log detailed external errors server-side (using `logger.error`), and return generic error messages (like "Upstream service error") to the client.
