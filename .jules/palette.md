## 2024-05-19 - Null-aware Elements vs Stable Dart Tooling

**Learning:** When applying UI fixes (like adding tooltips or adjusting layouts), modifying files that contain experimental Dart features (like `?action` from `null-aware-elements`) will cause local `flutter test` execution to fail unless the experimental flag is passed, or the code is patched back to stable syntax (`if (action != null) action!`).

**Action:** Before running tests, either ensure `flutter test` is run with `--enable-experiment=null-aware-elements` if the codebase relies on it, or safely convert experimental syntax to standard null-safe Dart if tests must pass on stable channels. If patching for tests, ensure the patches are reverted or committed cleanly so as not to break the original intent.
