## 2024-06-11 - [Prevent Internal Information Leakage]
**Vulnerability:** Upstream API error responses (`response.text`) were being directly returned to clients inside `HTTPException` detail.
**Learning:** Returning raw responses from third-party services (like NVIDIA or Data.gov) to the client could inadvertently leak infrastructure details, service configurations, stack traces from external systems, or validation details.
**Prevention:** Always log detailed HTTP errors server-side and raise `HTTPException` with a generic, sanitized detail message (like "Upstream service error") to prevent information leakage.
