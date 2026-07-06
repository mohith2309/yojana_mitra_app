## 2026-07-06 - [Sanitize Upstream Errors]
**Vulnerability:** Upstream API error messages (like rate limits, authentication failures, or 500s from third parties) were being passed directly back to clients via HTTPException.
**Learning:** Returning raw third-party errors can leak infrastructure details, internal IP addresses, stack traces, and backend topology to malicious clients.
**Prevention:** Always log raw errors securely server-side and return generic error messages (e.g., 'Bad Gateway' or 'Service Unavailable') to external clients.
