## 2023-10-27 - Added semantic labels to IconButton
**Learning:** In Flutter, icon-only widgets like `IconButton` often lack intrinsic semantic meaning for screen readers. While Material icons have default labels sometimes, they are often vague or context-dependent.
**Action:** Always ensure that an explicit `tooltip` is added to `IconButton` components to provide both visual hints and proper semantic labels for accessibility.
