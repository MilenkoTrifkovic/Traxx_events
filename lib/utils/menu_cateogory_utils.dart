const Set<String> kMenuCategoryKeys = {
  "appetizers",
  "salads",
  "soups",
  "entrees",
  "pasta",
  "sides",
  "breads",
  "desserts",
  "beverages",
  "buffet",
  "foodStations",
  "lateNightSnacks",
  "kidsMenu",
  "culturalRegional",
  "dietSpecific",
  "brunch",
  "bbq",
  "other",
};

String normalizeCategoryKey(String raw) {
  final rawStr = raw.trim();
  if (rawStr.isEmpty) return "other";
  if (kMenuCategoryKeys.contains(rawStr)) return rawStr;

  final lower = rawStr.toLowerCase().trim();
  final compact = lower.replaceAll(RegExp(r'[\s_-]'), '');

  if (compact == "foodstations") return "foodStations";
  if (compact == "latenightsnacks") return "lateNightSnacks";
  if (compact == "kidsmenu") return "kidsMenu";
  if (compact == "culturalregional") return "culturalRegional";
  if (compact == "dietspecific") return "dietSpecific";

  const map = {
    "appetizer": "appetizers",
    "appetizers": "appetizers",
    "salad": "salads",
    "salads": "salads",
    "soup": "soups",
    "soups": "soups",
    "entree": "entrees",
    "entrees": "entrees",
    "dessert": "desserts",
    "desserts": "desserts",
    "drink": "beverages",
    "drinks": "beverages",
    "beverage": "beverages",
    "beverages": "beverages",
    "buffet": "buffet",
    "brunch": "brunch",
    "bbq": "bbq",
    "other": "other",
  };

  return map[lower] ?? "other";
}

String categoryLabelFromKey(String key) {
  switch (key) {
    case "foodStations":
      return "Food Stations";
    case "lateNightSnacks":
      return "Late-Night Snacks";
    case "kidsMenu":
      return "Kids Menu";
    case "culturalRegional":
      return "Cultural / Regional";
    case "dietSpecific":
      return "Diet-Specific";
    case "bbq":
      return "BBQ";
    default:
      final k = (key.isEmpty ? "Other" : key);
      return k
          .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}')
          .trim()
          .replaceFirstMapped(RegExp(r'^.'), (m) => m.group(0)!.toUpperCase());
  }
}
