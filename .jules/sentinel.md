## 2024-07-14 - Information Leakage in API Gateway Error Responses
**Vulnerability:** Upstream API error details (like raw JSON with internal architecture or specific error codes from NVIDIA/DataGov APIs) were being exposed directly to the client via `HTTPException` in `backend/main.py`.
**Learning:** Returning unhandled or raw upstream exceptions to end users poses an information leakage risk. Attackers can use this to map internal service structures or glean API specifics.
**Prevention:** Always log verbose errors server-side and return generic, sanitized messages to the client.
