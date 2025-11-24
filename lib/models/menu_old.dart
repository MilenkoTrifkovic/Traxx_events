import 'package:traxx_wepapp/controller/admin_controllers/menu_controllers/menu_controllers_manager.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:uuid/uuid.dart';

class MenuItemOld {
  // For legacy compatibility: treat menuId as menuItemId
  String get menuItemId => menuId;
  final String menuId;
  String dishName;
  MenuCategory category;
  String description;
  String ingredientsAllergens;
  String imagePath;
  String? imageUrl;

  // Constructor with default values
  MenuItemOld({
    String? id,
    this.dishName = '',
    this.category = MenuCategory.other,
    this.description = '',
    this.ingredientsAllergens = '',
    this.imagePath = '',
  }) : menuId = id ?? Uuid().v4();

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': menuId,
      'dishName': dishName,
      'category': category
          .toString()
          .split('.')
          .last, // Store enum as string =>.name is better option
      'description': description,
      'ingredientsAllergens': ingredientsAllergens,
      'imageUrl': imagePath,
    };
  }
  // No menuItemId field or getter

  // Create MenuItem from Firestore document
  static MenuItemOld fromFirestore(Map<String, dynamic> doc) {
    return MenuItemOld(
      id: doc['id'] as String,
      dishName: doc['dishName'] as String? ?? '',
      category: MenuCategory.values.firstWhere(
        (e) => e.toString().split('.').last == doc['category'],
        orElse: () => MenuCategory.other,
      ),
      description: doc['description'] as String? ?? '',
      ingredientsAllergens: doc['ingredientsAllergens'] as String? ?? '',
      imagePath: doc['imageUrl'] as String? ?? '',
    );
  }

  // CopyWith method for updates
  MenuItemOld copyWith({
    String? dishName,
    MenuCategory? category,
    String? description,
    String? ingredientsAllergens,
    String? imageUrl,
  }) {
    return MenuItemOld(
      id: menuId, // Keep the same ID
      dishName: dishName ?? this.dishName,
      category: category ?? this.category,
      description: description ?? this.description,
      ingredientsAllergens: ingredientsAllergens ?? this.ingredientsAllergens,
      imagePath: imageUrl ?? imagePath,
    );
  }

  @override
  String toString() {
    return 'MenuItem(id: $menuId, dishName: $dishName, category: $category, description: $description, ingredientsAllergens: $ingredientsAllergens, imageUrl: $imagePath)';
  }

  // Update MenuItem with values from controllers
  void updateFromControllers(MenuItemControllers controllers) {
    dishName = controllers.dishName.text;
    description = controllers.description.text;
    ingredientsAllergens = controllers.ingredientsAllergens.text;
  }
}
