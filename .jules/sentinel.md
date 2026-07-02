## 2024-07-02 - Secure Error Handling in FastAPI
**Vulnerability:** Information Exposure via Error Messages (CWE-209). The FastAPI backend was exposing raw upstream API responses (via `response.text`) directly to the client in HTTP 500/400 exceptions.
**Learning:** Returning unhandled or raw upstream responses can leak sensitive internal paths, invalid API keys, or backend infrastructure details.
**Prevention:** Catch upstream API errors, log the verbose details server-side using the `logging` module, and return a sanitized, generic HTTP 502 (Bad Gateway) or 500 error to the client.
