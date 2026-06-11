## 2024-06-11 - Missing Tooltips on IconButtons
**Learning:** Found several `IconButton` widgets lacking the `tooltip` property, which reduces accessibility for screen readers and removes visual hints for users hovering over the button.
**Action:** Always add `tooltip` properties to `IconButton` widgets, especially when they only contain icons without text labels.
