/// Defines the different ways events can be sorted
enum SortType {
  /// Sort by event date (newest first)
  dateNewest,

  /// Sort by event date (oldest first)
  dateOldest,

  /// Sort by event name (A to Z)
  nameAZ,

  /// Sort by event name (Z to A)
  nameZA,
}

enum MenuItemsSortType {
  nameAZ,
  nameZA,
  priceLowHigh,
  priceHighLow,
  dateNewest,
  dateOldest,
}
