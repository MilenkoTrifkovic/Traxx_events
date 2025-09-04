import 'package:flutter/material.dart';
import 'package:traxx_wepapp/models/menu.dart';

class MenuItemControllers {
  final TextEditingController dishName;
  final TextEditingController description;
  final TextEditingController ingredientsAllergens;
  // Add any other controllers needed for a field

  MenuItemControllers({
    required this.dishName,
    required this.description,
    required this.ingredientsAllergens,
  });

  void dispose() {
    dishName.dispose();
    description.dispose();
    ingredientsAllergens.dispose();
  }
}

class MenuControllersManager {
  final Map<String, MenuItemControllers> _controllers = {};

  MenuItemControllers getControllers(MenuItem menuItem) {
    if (!_controllers.containsKey(menuItem.id)) {
      _controllers[menuItem.id] = MenuItemControllers(
        dishName: TextEditingController(text: menuItem.dishName),
        description: TextEditingController(text: menuItem.description),
        ingredientsAllergens:
            TextEditingController(text: menuItem.ingredientsAllergens),
      );
    }
    return _controllers[menuItem.id]!;
  }

  void disposeControllers(String fieldId) {
    _controllers[fieldId]?.dispose();
    _controllers.remove(fieldId);
  }

  void disposeAll() {
    _controllers.forEach((key, value) => value.dispose());
    _controllers.clear();
  }
}
