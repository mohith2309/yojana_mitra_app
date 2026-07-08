## 2025-05-24 - [Information Leakage in Error Responses]
**Vulnerability:** Upstream HTTP errors were passed directly to the client via `raise HTTPException(status_code=response.status_code, detail=response.text)`, exposing internal upstream API responses, endpoints, and potentially tokens.
**Learning:** Returning un-sanitized external API errors via FastAPI's `HTTPException` creates an information leakage risk.
**Prevention:** Always log raw external API errors securely server-side using Python's `logging` module and return generic, sanitized HTTP responses (like "502 Bad Gateway") to the client.
