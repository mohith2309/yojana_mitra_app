## 2024-07-13 - [Hardcoded Render Environment Variables]
**Vulnerability:** API keys (e.g., DATA_GOV_KEY) were hardcoded in `render.yaml` under the `envVars` section using `value: ...` instead of being securely managed.
**Learning:** Render deployment configurations (`render.yaml`) will leak secrets if keys are defined with `value`. They must use `sync: false` to force dashboard-based secret management.
**Prevention:** Always use `sync: false` for sensitive environment variables in `render.yaml` and remove hardcoded defaults from the corresponding Python backend configuration.
