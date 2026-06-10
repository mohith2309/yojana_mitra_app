## 2024-06-10 - Prevent Leakage of Upstream API Errors
**Vulnerability:** FastAPIs `HTTPException` was returning raw `response.text` from upstream APIs (like NVIDIA, Data.gov) directly to the client.
**Learning:** This exposes internal server architectures, raw provider errors, and potentially upstream IP addresses/tokens to the user/attacker. We must log errors server-side but return generic errors to clients.
**Prevention:** Always log the verbose error detailing the response body (`logger.error()`), but sanitize the `detail=` argument when raising an `HTTPException` so it is a non-specific client-facing message.
