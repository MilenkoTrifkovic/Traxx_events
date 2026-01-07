class MenuItemGroup {
  final String groupId;
  final String name;

  /// Canonical category key (e.g. "breads", "entrees")
  final String categoryKey;

  /// For guest radio behavior (for now = 1)
  final int maxPick;

  final List<String> itemIds;

  const MenuItemGroup({
    required this.groupId,
    required this.name,
    required this.categoryKey,
    this.maxPick = 1,
    required this.itemIds,
  });

  MenuItemGroup copyWith({
    String? groupId,
    String? name,
    String? categoryKey,
    int? maxPick,
    List<String>? itemIds,
  }) {
    return MenuItemGroup(
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      categoryKey: categoryKey ?? this.categoryKey,
      maxPick: maxPick ?? this.maxPick,
      itemIds: itemIds ?? this.itemIds,
    );
  }

  Map<String, dynamic> toMap() => {
        'groupId': groupId,
        'name': name,
        'categoryKey': categoryKey,
        'maxPick': maxPick,
        'itemIds': itemIds,
      };

  factory MenuItemGroup.fromMap(Map<String, dynamic> m) {
    final ids = (m['itemIds'] as List? ?? [])
        .map((e) => (e ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return MenuItemGroup(
      groupId: (m['groupId'] ?? '').toString().trim(),
      name: (m['name'] ?? '').toString().trim(),
      categoryKey: (m['categoryKey'] ?? 'other').toString().trim(),
      maxPick: (m['maxPick'] is num) ? (m['maxPick'] as num).toInt() : 1,
      itemIds: ids,
    );
  }
}
