import 'package:flutter/material.dart';

enum MenuCategory {
  appetizer(Icons.fastfood),
  entree(Icons.restaurant),
  dessert(Icons.cake),
  // drink(Icons.local_drink),
  other(Icons.more_horiz);

  final IconData icon;
  const MenuCategory(this.icon);
}
