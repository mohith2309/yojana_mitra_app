## $(date +%Y-%m-%d) - Add tooltips to Flutter IconButtons
**Learning:** In Flutter, icon-only buttons (\`IconButton\`) require a \`tooltip\` property to provide both visual hints and semantic labels for screen reader accessibility. If omitted, they represent a key accessibility failure point similar to missing \`aria-label\` attributes on web.
**Action:** When working on Flutter interfaces, always verify that every \`IconButton\` or interactive icon widget has a meaningful, context-aware \`tooltip\` defined.
