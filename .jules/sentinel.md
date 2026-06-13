## 2025-05-24 - Prevent upstream error leakage in FastAPI backend
**Vulnerability:** The FastAPI backend directly returned the actual upstream error message (`response.text`) via `HTTPException` detail whenever an upstream API like NVIDIA or DataGov failed.
**Learning:** Returning raw upstream error responses directly to the client can leak sensitive internal information, upstream architecture details, or stack traces.
**Prevention:** Always sanitize errors and implement the "fail securely" principle. Log verbose errors server-side and return generic, sanitized messages (like a generic 502) to clients.
