## 2025-05-18 - Prevented Information Exposure via HTTP Exceptions
**Vulnerability:** FastAPI endpoints directly passed raw upstream API error responses (`response.text`) to the client via `HTTPException`.
**Learning:** Returning un-sanitized upstream error responses can leak sensitive internal service architectures, keys, or stack traces.
**Prevention:** Always log verbose errors server-side and return generic, sanitized error messages (e.g. 502 Bad Gateway) to clients.
