## 2024-05-24 - Flutter IconButton Accessibility
**Learning:** In Flutter, the `tooltip` property on widgets like `IconButton` serves as the equivalent of an ARIA label for screen readers, in addition to providing hover hints. Ensuring all icon-only buttons have tooltips is a key accessibility/UX requirement.
**Action:** Always verify that `IconButton` widgets and other icon-only interactable elements contain a descriptive `tooltip` property when adding them or reviewing UI changes.
