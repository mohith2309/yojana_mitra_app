## 2024-05-24 - Accessibility: Missing tooltips for icon-only buttons
**Learning:** Icon-only buttons without explicit labels (e.g., `tooltip` in Flutter) are inaccessible to screen reader users and lack visual context for sighted users.
**Action:** Always add a `tooltip` property describing the action to every `IconButton` or similar icon-only interactive widget.
