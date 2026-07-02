## 2024-11-20 - [Accessibility Tooltips on Icon-Only Buttons]
**Learning:** Icon-only buttons without `tooltip` parameters cause accessibility issues because screen readers cannot vocalize their intent. Flutter allows these via `IconButton` widgets.
**Action:** When creating new `IconButton` widgets or reviewing existing ones, always ensure a `tooltip` parameter is provided to describe the action to screen readers.
