## 2024-05-15 - [Sanitize Upstream Error Messages]
**Vulnerability:** Upstream API error details (response.text) were exposed directly to the client via HTTPException.
**Learning:** Returning raw upstream error strings can leak internal architecture details, sensitive API keys, or provider information to malicious users.
**Prevention:** Log verbose error messages server-side and always return a generic, sanitized error message to the client.
