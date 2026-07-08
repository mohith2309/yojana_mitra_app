## 2024-07-25 - Added tooltips to IconButtons
**Learning:** Found several `IconButton` elements across the UI (search clear, scheme details open, save scheme, bottom sheet close) that consisted only of an icon without any accessibility labels. This causes screen readers to announce generic button types without context.
**Action:** Always verify that `IconButton` widgets define the `tooltip` property to provide semantic labels for screen readers and visual hints for mouse users.
