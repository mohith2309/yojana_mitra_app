## $(date +%Y-%m-%d) - Prevent Upstream Response Leakage via HTTPException
**Vulnerability:** Upstream API responses (including error messages) from external services like NVIDIA and Data.gov.in were being passed directly into the FastAPI `HTTPException` detail field, exposing them to the client.
**Learning:** Returning raw upstream error strings directly via an API can leak internal architecture details, internal paths, or the precise nature of integrations. The backend acts as an API Gateway and must sanitize its outputs.
**Prevention:** Catch upstream API errors, log the detailed text server-side using `logging`, and return generic, sanitized HTTP error codes (e.g. 502 Bad Gateway) and messages to the client.
