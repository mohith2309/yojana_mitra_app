## 2025-03-01 - [Prevent Leakage of Upstream API Details]
**Vulnerability:** Upstream API error responses (e.g., `response.text`) were being directly passed to clients via FastAPI `HTTPException`.
**Learning:** Raw upstream errors can expose sensitive internal service architecture, stack traces, and API limitations, which violates the "Fail securely" and "Do not expose sensitive data" principles.
**Prevention:** Log verbose external API errors server-side and always return sanitized, generic messages (e.g., "External API request failed.") to the client.