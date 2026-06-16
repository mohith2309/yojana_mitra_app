## 2024-06-16 - Add missing tooltips to IconButtons
**Learning:** Icon-only buttons (`IconButton`) in Flutter do not automatically provide semantic labels or visual hints. Without a `tooltip` property, these buttons lack accessibility for screen readers and visual hints on hover for desktop/web users. This is a common pattern to watch out for.
**Action:** Always verify that `IconButton` and similar icon-only interactive widgets include an explicit `tooltip` property (or an equivalent semantic wrapper) for both accessibility and improved usability.
