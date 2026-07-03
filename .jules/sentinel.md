## 2024-05-24 - [Information Leakage in API Error Responses]
**Vulnerability:** Upstream API error bodies (`response.text`) were being directly returned to clients via `HTTPException` detail fields.
**Learning:** Returning raw upstream error bodies exposes internal service architecture, parameters, and potentially sensitive debugging information or keys if the upstream API echoes them back.
**Prevention:** Always log verbose or raw errors on the server side (e.g., using `logging.error()`) and return generic, sanitized error messages (like "Upstream API error") to the client.
