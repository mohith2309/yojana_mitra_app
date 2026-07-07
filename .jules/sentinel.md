## $(date +%Y-%m-%d) - [Upstream API Error Information Leakage]
**Vulnerability:** The FastAPI backend directly passed raw upstream API responses (`response.text`) to the client via `HTTPException(detail=...)` across multiple endpoints (`/nvidia/chat`, `/nvidia/pii-detect`, `/nvidia/rerank`, `/data-gov/resource`).
**Learning:** Acting as an API gateway requires strict boundary management. Forwarding raw upstream errors can leak internal service configurations, stack traces, or upstream infrastructure details to end clients, posing a medium-priority information leakage risk.
**Prevention:** Always log verbose upstream errors server-side using standard `logging` and return sanitized, generic error responses (e.g., HTTP 502 "Upstream service error") to the client.
