## 2024-10-27 - Icon-only buttons lacking tooltips
**Learning:** In the Flutter codebase for BharatMitra, icon-only buttons (like `IconButton` without a semantic wrapper) frequently lack `tooltip` strings, reducing accessibility for screen readers and masking interactive context.
**Action:** Always provide explicit `tooltip` arguments when implementing or modifying `IconButton` components to ensure semantic labels are accessible to assistive technologies.
