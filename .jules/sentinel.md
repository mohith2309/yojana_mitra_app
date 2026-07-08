## 2024-07-08 - Prevent Leaking Upstream API Errors
**Vulnerability:** The FastAPI backend directly passed raw upstream API error details (response.text) to clients in HTTPExceptions.
**Learning:** This exposes internal architectural details and potentially sensitive data (like tokens) returned by third-party APIs during failures.
**Prevention:** Always log raw upstream errors server-side and return generic, sanitized HTTP error messages (like 'Upstream service error') to the client.
