
## 2024-05-18 - Missing Tooltips on IconButtons
**Learning:** Found several `IconButton` widgets missing `tooltip` properties in Flutter. Without `tooltip`, icon-only buttons lack semantic labels for screen readers, breaking accessibility.
**Action:** Always ensure icon-only buttons (like `IconButton`) have a `tooltip` property defined to provide both visual hints and semantic labels for screen reader accessibility in Flutter apps.
