## 2025-02-14 - Information Leakage in API Error Responses
**Vulnerability:** The FastAPI backend directly passed upstream API error responses (`response.text`) to the client via `HTTPException` detail strings.
**Learning:** Returning raw upstream error messages leaks sensitive internal information, upstream architecture details, or underlying service issues to end users, presenting a security risk. Verbose errors should be logged server-side.
**Prevention:** Always log detailed external API errors internally using `logging` or print statements, and return a generic, sanitized error message (e.g., "Upstream API request failed.") to the client.
