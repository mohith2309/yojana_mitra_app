## 2026-06-10 - Added Tooltips to IconButtons
**Learning:** In Flutter, `IconButton` widgets inherently act as purely visual elements unless accompanied by a label. Tooltips provide a dual benefit: visual hints for pointer users and semantic labels for screen readers. Missing tooltips on icon-only buttons create an accessibility gap, similar to missing ARIA labels in web interfaces.
**Action:** Always add a descriptive `tooltip` property to any `IconButton` that lacks visible text labels to ensure accessibility across devices.
