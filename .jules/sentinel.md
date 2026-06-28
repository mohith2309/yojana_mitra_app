## 2024-03-21 - [Prevent Upstream API Error Leakage]
**Vulnerability:** The backend leaked raw upstream API responses to the client by passing `response.text` to `HTTPException(detail=...)`. This could inadvertently expose sensitive internal architecture details, API keys, or IP addresses in error cases.
**Learning:** Returning raw responses from external services directly to clients in FastAPI apps bypasses proper abstraction and exposes the application to data leakage risks.
**Prevention:** Always log detailed upstream error responses server-side (using `logger.error`) and raise sanitized exceptions (like `HTTPException(status_code=502, detail="Upstream service error")`) to the client.
