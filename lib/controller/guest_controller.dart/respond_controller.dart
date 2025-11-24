import 'package:get/get.dart';
import 'package:traxx_wepapp/extensions/guest_response_extensions.dart';
import 'package:traxx_wepapp/models/event_questions.dart';
import 'package:traxx_wepapp/models/guest.dart';
import 'package:traxx_wepapp/models/guest_response.dart';
import 'package:traxx_wepapp/models/menu_old.dart';
import 'package:traxx_wepapp/services/firestore_services.dart';
import 'package:traxx_wepapp/services/storage_services.dart';
import 'package:traxx_wepapp/utils/enums/event_type.dart';
import 'package:traxx_wepapp/utils/enums/menu_category.dart';

class RespondController extends GetxController {
  //add mixin instead of current approach
  final String eventId;
  final List<MenuCategory> selectableCategories;
  final List<MenuItemOld> eventMenus;
  final int peopleAllowed;
  final ServiceType serviceType;
  List<EventQuestions> eventQuestions;

  RxInt currentStep = 0.obs;
  RxString errorMessage = ''.obs;
  RxInt badgeState = 0.obs;
  RxBool primaryGuestWillAttend = false.obs;
  RxInt companionsCount = 0.obs;
  RxBool nextButtonState = false.obs;
  RxBool expansionTitleExpanded = false.obs;
  RxBool menuValidation = true.obs;
  List<Function> validateFunctions = [];

  final String userId =
      'GtVe8orzBte68w3YkMKX'; //temporary userId before login implementation

  RxList<GuestResponse> allResponses = <GuestResponse>[].obs;
  List<String> emailInvites = [];

  RespondController._(this.eventId, this.selectableCategories, this.serviceType,
      this.peopleAllowed, this.eventMenus, this.eventQuestions);

  /// Factory method that creates and initializes a [RespondController] with all required data.
  ///
  /// Asynchronously loads:
  /// - Guest's companion limit from Firestore
  /// - Event questions configuration
  /// - Available menu items with their images
  ///
  /// Returns a fully initialized controller ready for guest responses.
  static Future<RespondController> create(String eventId,
      List<MenuCategory> selectableCategories, ServiceType serviceType) async {
    final int compaignonsLimit = await _initializeComplaignonsLimit(eventId);
    final questions = await _loadEventQuestions(eventId);
    final menus = await _loadEventMenus(eventId);
    return RespondController._(eventId, selectableCategories, serviceType,
        compaignonsLimit, menus, questions);
  }

  final FirestoreServices _firestoreServices = Get.find<FirestoreServices>();

  static Future<int> _initializeComplaignonsLimit(String eventId) async {
    FirestoreServices firestoreServices = Get.find<FirestoreServices>();
    try {
      final Guest guest = await firestoreServices.fetchGuestById(
          'GtVe8orzBte68w3YkMKX', eventId);
      final compaignonsLimit = guest.companions;
      return compaignonsLimit;
    } on Exception catch (e) {
      print('Compaingons limit initialization failed!');
      // errorMessage.value = 'Error';
      throw Exception('');
    }
  }

  void setPrimaryGuestAttendance(bool isAttending) {
    _removeAllCompanions();
    if (isAttending) {
      if (_checkIfPrimaryGuestAdded()) {
        print('Primary guest already added.');
        return;
      }
      allResponses.add(GuestResponse(
          guestId: userId,
          isAttending: true,
          questionAnswers: _generateNewQuestions()));

      primaryGuestWillAttend.value = true;
      badgeState.value = 1;
    } else {
      allResponses.removeWhere((guest) => guest.guestId == userId);
      primaryGuestWillAttend.value = false;
      badgeState.value = -1;
    }
    nextButtonState.value = true;
  }

  bool _checkIfPrimaryGuestAdded() {
    return allResponses.any((guest) => guest.guestId == userId);
  }

  void _removeAllCompanions() {
    allResponses.removeWhere((guest) => guest.guestId != userId);
    companionsCount.value = 0;
  }

  /// Add companions to the guest responses list
  /// Ensures total responses do not exceed peopleAllowed
  /// Clears previous companions before adding new ones
  void addCompanionsToAllResponses(int amount) {
    _removeAllCompanions(); //removes all companions
    if ((allResponses.length + emailInvites.length + amount) <= peopleAllowed) {
      for (var i = 0; i < amount; i++) {
        allResponses.add(GuestResponse(
            inviterId: userId,
            isAttending: true,
            questionAnswers: _generateNewQuestions()));
        companionsCount.value = amount;
      }
    } else {
      errorMessage.value = 'Invalid number of companions';
      print('Error: ${errorMessage.value}');
      return;
    }
    print('Companions count set to ${allResponses.length}');
  }

  /// Generate new List of questions for a guest response
  List<EventQuestions> _generateNewQuestions() {
    return eventQuestions.map((element) {
      return EventQuestions.copyFrom(element);
    }).toList();
  }

  ///Fetch event questions from Firestore and set to eventQuestions list
  static Future<List<EventQuestions>> _loadEventQuestions(
      String eventId) async {
    //EROR Handling
    FirestoreServices firestoreServices = Get.find<FirestoreServices>(); //added
    final questions = await firestoreServices.fetchAllSetQuestions(eventId);
    return questions;
  }

  static Future<List<MenuItemOld>> _loadEventMenus(String eventId) async {
    //ERROR handling
    FirestoreServices firestoreServices = Get.find<FirestoreServices>(); //added
    final StorageServices storageServices = Get.find<StorageServices>(); //added
    final menus = await firestoreServices.getMenus(eventId);

    for (final menu in menus) {
      if (menu.imagePath.isNotEmpty) {
        menu.imageUrl = await storageServices.loadImageURL(menu.imagePath);
      }
    }
    return menus;
  }

  void setSelectedDish(MenuItemOld dish, int responseId) {
    allResponses[responseId].menus[dish.category.name] = dish.menuItemId;
    allResponses.refresh();
  }

  List<MenuCategory> getActiveCategories() {
    final listOfCategories = getMenusByCategory().keys.toList();
    return listOfCategories;
  }

  Map<MenuCategory, List<MenuItemOld>> getMenusByCategory() {
    final menusByCategory = <MenuCategory, List<MenuItemOld>>{};

    for (final menu in eventMenus) {
      if (!menusByCategory.containsKey(menu.category)) {
        menusByCategory[menu.category] = [];
      }
      menusByCategory[menu.category]!.add(menu);
    }

    return menusByCategory;
  }

  void onStepContinue() {
    if (currentStep.value < 2) {
      // Handle special case for non-attending primary guest
      if (currentStep.value == 0 && !primaryGuestWillAttend.value) {
        currentStep.value = 2; // Skip to review step
        resetNextButton(false);
        return;
      }

      // if (currentStep.value == 1) {
      //   submitSecondStep();
      // }

      currentStep.value++;
      // resetNextButton(false);
    }
  }

  void onStepCancel() {
    if (currentStep.value > 0) {
      // Handle special case when coming back from review after non-attendance
      if (currentStep.value == 2 && !primaryGuestWillAttend.value) {
        currentStep.value = 0;
        resetNextButton(true);
        return;
      }

      currentStep.value--;
      resetNextButton(true);
    }
  }

  void resetNextButton(bool state) {
    nextButtonState.value = state;
  }

  /// Expand or collapse all expansion tiles

//save responses to firestore
  Future<void> submitAllResponses() async {
    print('Submitting response...');

    try {
      await _firestoreServices.saveGuestResponses(eventId, allResponses);
    } on Exception catch (e) {
      print('Error submitting responses: $e');
      errorMessage.value = 'Failed to submit responses';
    }
    print('Responses submitted successfully.');
  }

  void submitSecondStep() {
    print('Submitting second step responses...');
    print('Total responses: ${allResponses.length}');
    for (var resp in allResponses) {
      print(resp.menus);
    }
  }

  /// Expand or collapse expansion tiles
  ///
  /// If index is provided, toggles that specific tile
  /// If no index is provided, expands all tiles
  void changeExpansionState({int? index}) {
    if (index != null && index >= 0 && index < allResponses.length) {
      allResponses[index].isExpanded = !allResponses[index].isExpanded;
      allResponses.refresh(); // Notify listeners about the change
    } else {
      for (int i = 0; i < allResponses.length; i++) {
        allResponses[i].isExpanded = true;
        allResponses.refresh(); // Notify listeners about the change
      }
    }
  }

  bool _validateMenuFields() {
    bool returningValue = true;
    for (int i = 0; i < selectableCategories.length; i++) {
      if (allResponses.any((response) =>
          !response.menus.containsKey(selectableCategories[i].name))) {
        menuValidation.value = false;
        returningValue = false;
        break;
      }
    }
    return returningValue;
  }

  void registerFormFieldValidation(Function validate) {
    validateFunctions.add(validate);
  }

  bool validateAll() {
    bool menuValidation = _validateMenuFields();
    bool formValidation = true;
    for (var v in validateFunctions) {
      if (!v()) {
        formValidation = false;
      }
    }
    return formValidation && menuValidation;
  }

  String categoryFieldPlaceholder(MenuCategory category) {
    String placeholder = serviceType == ServiceType.plated
        ? (selectableCategories.contains(category) ? 'Select' : 'Preview')
        : 'Preview';
    return placeholder;
  }

  /// Checks if a category field should show an error state.
  ///
  /// Returns true if:
  /// - Validation is failing AND
  /// - Category is selectable AND
  /// - No menu item has been selected for this category
  bool shouldShowCategoryError(
    MenuCategory category,
    int responseId,
    bool isSelectable,
  ) {
    if (menuValidation.value) {
      return false;
    }

    bool hasSelection = allResponses[responseId].menus[category.name] != null;
    if (hasSelection) {
      return false;
    }

    return isSelectable;
  }

  List<Map<String, String>> getAllResponsesAsTableRows() {
    return allResponses
        .map((response) => response.toTableRow(eventMenus))
        .toList();
  }
}
