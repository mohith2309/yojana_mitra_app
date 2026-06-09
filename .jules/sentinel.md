## 2025-06-09 - [Fix HTTPException info leakage]
**Vulnerability:** HTTPException was exposing response.text, which contained error messages directly from the upstream server (e.g. data.gov API or NVIDIA API). This could leak sensitive internal structures or errors.
**Learning:** Returning unhandled external server responses as HTTP detail causes info leakage.
**Prevention:** Mask details using generic error messages like "Upstream service error".
