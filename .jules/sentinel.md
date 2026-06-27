
## 2024-05-27 - [Information Disclosure in HTTPException]
**Vulnerability:** Fast API routes returning raw upstream API error responses (`response.text`) via `HTTPException` detail fields.
**Learning:** This exposes the application to Information Disclosure. Upstream API errors might leak internal infrastructure details, stack traces, or other sensitive information directly to end-users.
**Prevention:** Always log the actual verbose errors securely server-side, and return generic, sanitized messages to the client (e.g., "Upstream API request failed"). Use logging to capture the detailed upstream response.
