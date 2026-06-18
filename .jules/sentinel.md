## 2024-06-18 - Information Leakage via Error Details
**Vulnerability:** FastAPIs `HTTPException` was returning raw upstream API error responses (`response.text`) directly to the client via the `detail` parameter.
**Learning:** This exposes upstream internals, stack traces, and configurations to unauthorized users, violating the "Fail securely" principle.
**Prevention:** Always log verbose error details server-side using standard logging (e.g., `logger.error`), and return generic, sanitized messages (like `"External API request failed"`) to the client.
