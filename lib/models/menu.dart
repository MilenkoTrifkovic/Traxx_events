import 'package:traxx_wepapp/controller/host_controllers/menu_controllers/menu_controllers_manager.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';
import 'package:uuid/uuid.dart';

class MenuItem {
  final String id;
  String dishName;
  MenuCategory category;
  String description;
  String ingredientsAllergens;
  String imagePath;
  String? imageUrl;

  // Constructor with default values
  MenuItem({
    String? id,
    this.dishName = '',
    this.category = MenuCategory.other,
    this.description = '',
    this.ingredientsAllergens = '',
    this.imagePath = '',
  }) : id = id ?? Uuid().v4();

  // Convert to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'dishName': dishName,
      'category': category.toString().split('.').last, // Store enum as string
      'description': description,
      'ingredientsAllergens': ingredientsAllergens,
      'imageUrl': imagePath,
    };
  }

  // Create MenuItem from Firestore document
  static MenuItem fromFirestore(Map<String, dynamic> doc) {
    return MenuItem(
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
  MenuItem copyWith({
    String? dishName,
    MenuCategory? category,
    String? description,
    String? ingredientsAllergens,
    String? imageUrl,
  }) {
    return MenuItem(
      id: id, // Keep the same ID
      dishName: dishName ?? this.dishName,
      category: category ?? this.category,
      description: description ?? this.description,
      ingredientsAllergens: ingredientsAllergens ?? this.ingredientsAllergens,
      imagePath: imageUrl ?? imagePath,
    );
  }

  @override
  String toString() {
    return 'MenuItem(id: $id, dishName: $dishName, category: $category, description: $description, ingredientsAllergens: $ingredientsAllergens, imageUrl: $imagePath)';
  }

  // Update MenuItem with values from controllers
  void updateFromControllers(MenuItemControllers controllers) {
    dishName = controllers.dishName.text;
    description = controllers.description.text;
    ingredientsAllergens = controllers.ingredientsAllergens.text;
  }
}
