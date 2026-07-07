## 2024-05-18 - Prevented information disclosure of internal API responses

**Vulnerability:** The FastAPI backend directly passed raw upstream API responses (e.g. from NVIDIA, data.gov.in) through `HTTPException` back to the client (`raise HTTPException(status_code=response.status_code, detail=response.text)`). This leaks internal application logic, third-party error schemas, and potentially sensitive stack traces or metadata to end users, aiding attackers in mapping the backend architecture.
**Learning:** Returning upstream error texts as-is is a common vector for information disclosure in microservices. It should always be handled server-side rather than bubbling up.
**Prevention:** Always log the verbose, detailed API error server-side (using `logger.error()`) and return a generic, sanitized HTTP 502/500 error to the client to mask the underlying infrastructure.
