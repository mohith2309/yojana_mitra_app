## 2024-06-07 - Hardcoded Default in Environment Variable Lookup
**Vulnerability:** A hardcoded API key was exposed as the fallback value in an `os.getenv` call for `DATA_GOV_KEY` within `citizen_api.py`.
**Learning:** Even when using environment variables for secrets, developers may sometimes carelessly provide the real secret as the fallback argument to `os.getenv` or similar functions, effectively hardcoding it and defeating the purpose.
**Prevention:** Audit all `os.getenv` and similar configuration lookups to ensure the fallback arguments do not contain real secrets, defaulting to empty strings or raising explicit initialization errors instead.
