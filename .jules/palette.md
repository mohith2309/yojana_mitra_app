## 2024-05-18 - Missing tooltips on Icon-only buttons
**Learning:** Found multiple instances of icon-only `IconButton`s in the codebase that lack `tooltip` attributes, making them inaccessible to screen readers and lacking hover context for standard users.
**Action:** When adding or auditing icon-only buttons, always ensure a descriptive `tooltip` attribute is provided to improve accessibility and UX.
