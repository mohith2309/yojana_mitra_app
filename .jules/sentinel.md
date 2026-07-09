## $(date +%Y-%m-%d) - Prevent Upstream API Error Leakage
**Vulnerability:** Upstream API error details (like raw `response.text`) were being directly passed to the client via `HTTPException(detail=response.text)`.
**Learning:** Returning raw upstream error responses directly to the client can leak sensitive internal information, such as service architectures, paths, or stack traces of the underlying APIs.
**Prevention:** Always sanitize upstream errors before returning them to the client. Return generic error messages to the client and log the verbose, raw error server-side.
