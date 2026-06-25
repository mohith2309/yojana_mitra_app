## 2024-05-18 - Fix Upstream Error Leakage
**Vulnerability:** Upstream API error details (like HTTP status codes and raw error responses from internal services) were directly propagated to end-users via `HTTPException`.
**Learning:** Returning `response.text` exposes internal architecture and dependency structure to potential attackers, breaking the "Fail Securely" principle.
**Prevention:** Always log detailed external API errors server-side using the `logging` module and return generic, sanitized messages (e.g. `502 Bad Gateway`, "Upstream service error") to the client.
