// ENHANCED SCHEMES TAB WITH TAG FILTERING
// Replace the _buildSchemesTab() method in lib/main.dart with this version

// Add this to _AssistantHomePageState class:
Set<SchemeTag> _selectedTags = {};
bool _showOnlyMatched = false;

// Replace _buildSchemesTab() with:
Widget _buildSchemesTab() {
  final query = _schemeSearch.toLowerCase();
  final all = schemes;

  // Filter by search query
  var filtered = (query.isEmpty
      ? all
      : all.where(
          (s) =>
              s.name.toLowerCase().contains(query) ||
              s.category.toLowerCase().contains(query) ||
              s.benefit.toLowerCase().contains(query) ||
              s.keywords.any((k) => k.contains(query)),
        ))
      .toList();

  // Filter by selected tags
  if (_selectedTags.isNotEmpty) {
    filtered = filtered
        .where((s) => _selectedTags.every((tag) => s.tags.contains(tag)))
        .toList();
  }

  // Filter by matched status
  if (_showOnlyMatched) {
    final matchedNames = _matches.map((m) => m.scheme.name).toSet();
    filtered = filtered.where((s) => matchedNames.contains(s.name)).toList();
  }

  // Put matched schemes first
  final matchedNames = _matches.map((m) => m.scheme.name).toSet();
  filtered.sort((a, b) {
    final aM = matchedNames.contains(a.name) ? 0 : 1;
    final bM = matchedNames.contains(b.name) ? 0 : 1;
    return aM.compareTo(bM);
  });

  return SafeArea(
    child: Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              const Text(
                'Find Schemes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE85D04).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE85D04)),
                ),
                child: Text(
                  '${filtered.length}',
                  style: const TextStyle(
                    color: Color(0xFFE85D04),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Search box
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF1E2D40),
              hintText: 'Search: widow, farmer, student, housing...',
              hintStyle: const TextStyle(color: Color(0xFF6B7280)),
              prefixIcon:
                  const Icon(Icons.search, color: Color(0xFF9CA3AF)),
              suffixIcon: _schemeSearch.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          color: Color(0xFF9CA3AF)),
                      onPressed: () =>
                          setState(() => _schemeSearch = ''),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (v) => setState(() => _schemeSearch = v),
          ),
        ),
        // Tag filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // "Matched" chip
                if (_matches.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('For You'),
                      selected: _showOnlyMatched,
                      onSelected: (v) =>
                          setState(() => _showOnlyMatched = v),
                      backgroundColor:
                          const Color(0xFF1E2D40),
                      selectedColor: const Color(0xFFE85D04)
                          .withValues(alpha: 0.3),
                      labelStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),
                  ),
                // Tag chips
                ...[
                  (SchemeTag.widow, 'Widow'),
                  (SchemeTag.farmer, 'Farmer'),
                  (SchemeTag.student, 'Student'),
                  (SchemeTag.women, 'Women'),
                  (SchemeTag.housing, 'Housing'),
                  (SchemeTag.disability, 'Disability'),
                  (SchemeTag.rural, 'Rural'),
                  (SchemeTag.lowIncome, 'Low Income'),
                ]
                    .map((pair) {
                  final (tag, label) = pair;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(label),
                      selected:
                          _selectedTags.contains(tag),
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedTags.add(tag);
                          } else {
                            _selectedTags.remove(tag);
                          }
                        });
                      },
                      backgroundColor:
                          const Color(0xFF1E2D40),
                      selectedColor: const Color(0xFFE85D04)
                          .withValues(alpha: 0.3),
                      labelStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(20),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        // Results
        if (_matches.isNotEmpty && !_showOnlyMatched)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                const Icon(Icons.star,
                    color: Color(0xFFE85D04), size: 14),
                const SizedBox(width: 4),
                Text(
                  '${matchedNames.length} match your profile',
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        // Scheme list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off,
                          size: 48,
                          color: Color(0xFF374151)),
                      const SizedBox(height: 12),
                      const Text(
                        'No schemes found',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedTags.isEmpty && query.isEmpty
                            ? 'Try changing filters'
                            : 'Try different keywords',
                        style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 12),
                      ),
                      if (_selectedTags.isNotEmpty ||
                          query.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 12),
                          child: TextButton(
                            onPressed: () => setState(() {
                              _selectedTags.clear();
                              _schemeSearch = '';
                            }),
                            child: const Text('Clear filters'),
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      16, 0, 16, 24),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final scheme = filtered[i];
                    final match = _matches
                        .where((m) =>
                            m.scheme.name ==
                            scheme.name)
                        .firstOrNull;
                    return Padding(
                      padding:
                          const EdgeInsets.only(
                              bottom: 10),
                      child: match != null
                          ? _SchemeCard(
                              match: match,
                              saved: _savedSchemes
                                  .contains(
                                      scheme
                                          .name),
                              onSave: () =>
                                  _toggleSaved(
                                      scheme),
                              onOpenOfficial: () =>
                                  _openOfficialPortal(
                                      scheme),
                            )
                          : _SchemeListTile(
                              scheme: scheme,
                              saved: _savedSchemes
                                  .contains(
                                      scheme
                                          .name),
                              onSave: () =>
                                  _toggleSaved(
                                      scheme),
                              onOpen: () =>
                                  _openOfficialPortal(
                                      scheme),
                            ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
