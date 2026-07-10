## 2024-07-10 - Flutter IconButton Accessibility
**Learning:** In Flutter apps, `IconButton` widgets without a defined `tooltip` property are effectively invisible to screen readers (like TalkBack or VoiceOver) as they provide no semantic label, creating severe accessibility blockers.
**Action:** Always verify that every `IconButton` or icon-only widget has a descriptive `tooltip` or `semanticsLabel` property set, especially when they control critical actions like dismissing modals or saving state.
