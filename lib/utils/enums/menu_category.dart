import 'package:flutter/material.dart';

enum MenuCategory {
  appetizer(Icons.fastfood, true),
  entree(Icons.restaurant, false),
  dessert(Icons.cake, true),
  drink(Icons.local_drink, true),
  other(Icons.more_horiz, false);

  final IconData icon;
  final bool isVeg;
  const MenuCategory(this.icon, this.isVeg);
}
