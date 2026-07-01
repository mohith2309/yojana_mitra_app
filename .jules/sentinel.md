## 2024-03-22 - Prevent Internal Architecture Leakage in Upstream API Errors
**Vulnerability:** The FastAPI backend directly passed upstream API error responses (`response.text`) to the client via `HTTPException`. This could expose internal service architecture details, upstream stack traces, or poorly masked API keys.
**Learning:** Returning raw upstream errors in a gateway API breaks the abstraction layer and can leak sensitive information. This was present across multiple endpoints calling external AI and data APIs.
**Prevention:** Always log verbose errors server-side using standard logging mechanisms, and return generic, sanitized messages to the client (e.g., "Upstream API error occurred") to prevent information disclosure.
