## 2025-02-21 - [Upstream API Error Leakage]
**Vulnerability:** The FastAPI backend directly returned upstream error details via HTTPException detail fields.
**Learning:** Returning `response.text` from upstream providers to clients can leak API internals and stack traces.
**Prevention:** Catch upstream API failures, securely log the raw error on the server, and only return a generic 502 status code and message to the client.
