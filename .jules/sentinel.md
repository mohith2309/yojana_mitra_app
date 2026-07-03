## 2025-07-03 - [Fix Information Leakage via HTTPException Details]
**Vulnerability:** The FastAPI backend directly passed raw upstream API responses (`response.text`) to clients inside the `detail` attribute of `HTTPException` on 4xx/5xx responses (affecting NVIDIA and Data.gov.in integration routes).
**Learning:** Returning un-sanitized external API errors exposes internal system context, potential internal paths, stack traces, and backend configurations, increasing the attack surface.
**Prevention:** Fail securely by using server-side logging (e.g., `logger.error()`) for detailed error tracing, while returning generic, sanitized error messages (e.g., "Upstream service error") to clients.
