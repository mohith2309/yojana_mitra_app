## 2024-06-25 - Icon Button Tooltips in Flutter
**Learning:** In Flutter, `IconButton` widgets used for icon-only buttons do not have inherent semantic labels for screen readers unless a `tooltip` is explicitly provided. Tooltips function identically to `aria-label` on the web, improving both visual hover context and accessibility.
**Action:** Always ensure any icon-only `IconButton` in Flutter includes a descriptive `tooltip` property.
