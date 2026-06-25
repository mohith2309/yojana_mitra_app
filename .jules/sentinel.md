## 2025-03-03 - [Fix generic error messages to not expose external API responses]
**Vulnerability:** HTTPException was exposing `response.text` from external APIs (like NVIDIA, Data.gov) to the client, which could leak internal service architecture or sensitive upsteam data.
**Learning:** Returning detailed upstream failure responses directly exposes internal context or formats to external users.
**Prevention:** Avoid passing raw upstream API error responses directly to the client via `HTTPException` detail. Log verbose errors server-side instead, returning generic, sanitized messages to prevent leakage of internal service architecture.
