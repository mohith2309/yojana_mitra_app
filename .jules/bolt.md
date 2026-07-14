## 2024-05-24 - Avoid O(n²) List Lookups in Flutter UI Building
**Learning:** The Flutter ListView builder frequently rebuilt UI elements causing nested loops due to an O(n) `.where()` operation inside. Caching matches in a hash map earlier avoids significant UI thread bottlenecks when filtering schemes.
**Action:** Always pre-calculate and cache frequent lookups in an O(1) hash map before passing data to UI builders or complex sort operations.
