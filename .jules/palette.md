## 2025-02-13 - Add Tooltips to IconButton
**Learning:** Found several `IconButton` instances in the codebase missing a `tooltip` attribute. When an icon-only button lacks a tooltip, screen reader accessibility is compromised and users miss out on vital hover hints, particularly confusing in lists (like saved schemes) or app bars.
**Action:** Always ensure any `IconButton` or visually icon-only interactive element includes a descriptive `tooltip` attribute outlining its action.
