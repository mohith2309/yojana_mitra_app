## 2025-02-28 - Added Tooltips to IconButtons for Screen Reader Accessibility
**Learning:** Found multiple instances of `IconButton` widgets without descriptive text, making them challenging for screen reader users to understand.
**Action:** Always ensure icon-only buttons (like `IconButton`) have a `tooltip` property defined. In Flutter, this automatically acts as a semantic label for screen readers.
