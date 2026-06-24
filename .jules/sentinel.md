## 2024-05-27 - [Information Leakage via HTTPException]
**Vulnerability:** Upstream API error details (e.g. `response.text`) were being directly raised and passed to the client via `HTTPException(detail=response.text)` in multiple FastAPI endpoints within `backend/main.py`.
**Learning:** Returning raw upstream error messages directly to the client can leak sensitive internal service information, architectural details, or upstream credentials that might be embedded in the original API's failure response.
**Prevention:** Always catch upstream HTTP errors, log the verbose details server-side using a standard logger (`logger.error`), and raise a generic, sanitized HTTP exception (e.g., "Upstream service error") to the client.
