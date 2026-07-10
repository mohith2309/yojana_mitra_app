## 2025-02-14 - Prevent Raw Error Leakage

**Vulnerability:** Upstream APIs errors (NVIDIA, DataGov) were exposed natively via `HTTPException(detail=response.text)` to users and failed securely. This leaks internal upstream service information and upstream stack traces.
**Learning:** Do not pass raw responses to clients via FastAPI `HTTPException`.
**Prevention:** Sanitize responses and log `response.text` locally.
