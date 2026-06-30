## 2024-05-18 - Prevented leakage of internal upstream service errors
**Vulnerability:** The FastAPI backend directly returned upstream `response.text` as the detail in `HTTPException`, which could expose raw API error messages, stack traces, and internal server structure to unauthenticated end users.
**Learning:** Returning unhandled external responses to the user gives attackers insight into our infrastructure, third-party services, and internal handling.
**Prevention:** Log external errors explicitly server-side using `logger.error` and return sanitized, generic error strings such as `"Upstream service error"` to the client.
