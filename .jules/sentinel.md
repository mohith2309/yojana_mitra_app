## 2025-02-23 - [Information Exposure via Upstream Responses]
**Vulnerability:** FastApi endpoints were raising `HTTPException` with `detail=response.text` when upstream APIs returned HTTP errors.
**Learning:** Directly passing upstream response bodies to client error details can expose internal stack traces, third-party error structures, or sensitive information about upstream infrastructure.
**Prevention:** Always use generic error messages (e.g., `Upstream API error`) in client-facing exceptions and instead log the detailed upstream response internally for debugging.
