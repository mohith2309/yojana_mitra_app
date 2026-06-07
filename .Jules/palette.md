## 2024-03-24 - Accessibility improvements
**Learning:** Found multiple instances where `IconButton` widgets in Flutter lacked appropriate `tooltip` or `semanticLabel` attributes. These are crucial for screen reader users and those navigating with keyboards or other assistive technologies. Missing tooltips mean that icon-only buttons remain inaccessible as screen readers don't know what to announce for them.
**Action:** Adding tooltips to `IconButton` widgets provides an accessible label for screen readers and displays a helpful text hint on long press/hover for visual users.
