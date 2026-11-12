## 2024-03-24 - Icon Button Accessibility
**Learning:** Flutter's `IconButton` widget does not automatically provide a tooltip for accessibility (like ARIA labels in web). Screen readers and hover states need this explicit `tooltip` property to be useful.
**Action:** Always add a descriptive `tooltip` to `IconButton`s, especially when they are icon-only buttons.
