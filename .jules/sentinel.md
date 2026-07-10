## 2024-05-24 - Sanitize Upstream API Errors to Prevent Information Leakage
**Vulnerability:** Information Exposure. FastAPI backend was directly passing raw `response.text` from failed upstream API calls into the `HTTPException` detail.
**Learning:** Returning raw upstream errors directly to the client can inadvertently expose sensitive internal infrastructure details, stack traces, or upstream credentials to end-users.
**Prevention:** Always log raw verbose errors server-side (e.g., using `print()` or `logger.error()`) for debugging, and return sanitized, generic error messages (e.g., "Upstream API error") to the client.
