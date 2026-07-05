## 2026-07-05 - [Hide Upstream Error Responses from Client]
**Vulnerability:** Fast API code exposed raw `response.text` from upstream services (NVIDIA and Data Gov APIs) via `HTTPException` directly to clients, which could leak internal configuration details, underlying prompts, or credentials depending on what the upstream API echoes in an error.
**Learning:** Returning unhandled or unsanitized upstream errors to downstream consumers can unintentionally leak sensitive backend data.
**Prevention:** Catch upstream API failures, log the actual failure strictly server-side for debugging, and return a sanitized, generic 502 error to the user.
