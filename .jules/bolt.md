## 2025-02-15 - Replace O(N) list scan with O(1) Map lookup in ListView.builder
**Learning:** In Flutter's `ListView.builder`, executing an O(N) list scan (like `list.where().firstOrNull`) inside `itemBuilder` results in O(N*M) time complexity during scrolling, creating severe frame drops for long lists.
**Action:** Always pre-compute a lookup Map (e.g., `final map = {for (var item in list) item.id: item};`) before building the list, and use O(1) map lookups inside `itemBuilder`.
