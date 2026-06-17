## $(date +%Y-%m-%d) - Adding Tooltips to Icon-Only Buttons
**Learning:** Icon-only buttons (like `IconButton` in Flutter) lack semantic labels by default, meaning screen readers (like VoiceOver/TalkBack) announce them generically as "button" without context, making the app inaccessible to visually impaired users.
**Action:** Always add the `tooltip` property to any `IconButton` or icon-only interactive widget. The tooltip serves a dual purpose: it provides a hover hint for mouse users and automatically becomes the semantic `aria-label` equivalent for screen readers.
