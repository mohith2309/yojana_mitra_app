## 2025-02-14 - Information Leakage in Upstream Errors
**Vulnerability:** Upstream API error responses (like NVIDIA or Data.gov API errors) were being exposed directly to the client via `HTTPException` detail.
**Learning:** Returning unhandled external error text can leak internal infrastructure topology, sensitive API provider error structures, or connection string details to malicious clients.
**Prevention:** Catch upstream errors, log the actual exception details internally using python's `logging` module, and return a sanitized, generic 502 HTTP error message (e.g., "Upstream service error") to the end user.
