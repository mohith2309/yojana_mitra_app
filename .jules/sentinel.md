## 2024-05-24 - [MEDIUM] Sanitize upstream API error responses
**Vulnerability:** The application was passing raw upstream API error responses (`response.text`) directly to the client via `HTTPException` detail.
**Learning:** Leaking raw API responses can expose internal service architectures and potentially sensitive data in upstream responses to malicious actors.
**Prevention:** Log verbose errors server-side instead, and return generic, sanitized messages to prevent leakage.
