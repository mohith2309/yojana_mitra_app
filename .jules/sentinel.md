
## 2024-05-28 - [Information Leakage in FastAPI Upstream Error Handling]
**Vulnerability:** Upstream API responses (from external services like NVIDIA and Data.gov) were directly passed to the client via `HTTPException(detail=response.text)`.
**Learning:** This exposes internal service architecture, exact parameter formats, and potentially stack traces or internal secrets to end-users on error boundaries.
**Prevention:** Always log detailed HTTP error bodies internally (e.g., via `logging.error()`) and return generic, sanitized messages (e.g., "Upstream service returned an error") to the client.
