import 'package:flutter/material.dart';

enum MenuCategory {
  appetizers(Icons.fastfood, true),
  salads(Icons.eco, true),
  soups(Icons.ramen_dining, true),
  entrees(Icons.restaurant, false),
  pasta(Icons.dinner_dining, true),
  sides(Icons.rice_bowl, true),
  breads(Icons.bakery_dining, true),
  desserts(Icons.cake, true),
  beverages(Icons.local_drink, true),
  buffet(Icons.local_dining, false),
  foodStations(Icons.store_mall_directory, false),
  lateNightSnacks(Icons.nightlife, false),
  kidsMenu(Icons.child_care, true),
  culturalRegional(Icons.public, false),
  dietSpecific(Icons.health_and_safety, true),
  brunch(Icons.free_breakfast, true),
  bbq(Icons.outdoor_grill, false),
  other(Icons.more_horiz, false);

  final IconData icon;
  final bool isVeg;
  const MenuCategory(this.icon, this.isVeg);
}
