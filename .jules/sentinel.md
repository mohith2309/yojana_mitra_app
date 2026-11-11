## 2024-05-24 - [Remove hardcoded DATA_GOV_KEY]
**Vulnerability:** Hardcoded API key (DATA_GOV_KEY) found in citizen_api.py and render.yaml.
**Learning:** API keys should not be hardcoded in the codebase, even as default values or in configuration files, as they can be easily extracted from the source code.
**Prevention:** Always use environment variables for sensitive data and ensure they are not checked into version control. In render.yaml, use `sync: false` to manage secrets via the dashboard.
