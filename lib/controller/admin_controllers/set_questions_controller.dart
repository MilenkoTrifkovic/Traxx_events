import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/admin_controllers/host_controller.dart';
import 'package:traxx_wepapp/models/event_questions.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/utils/enums/input_type.dart';
import 'package:traxx_wepapp/utils/static_data.dart';

/// Controller that manages guest input fields for an event.
/// It fetches guest form configuration from Firestore via HostServices,
/// manages a list of custom guest fields, and validates/saves those fields.
class SetQuestionsController {
  RxBool isLoading = true.obs;

  /// Reference to the HostController (used to get current event details).
  // final EventListController eventController = Get.find<EventListController>();
  final HostController hostController =
      Get.find<HostController>(); //new approach
  // final AuthController authController = Get.find<AuthController>();

  /// Service that handles communication with the Firestore backend.
  late final FirestoreServices firestoreServices;

  /// Keeps track of the next available ID for new guest fields.
  int _nextId = 0;

  /// Default fields, added in constructor, shown if no fields exist in Firestore.
  final Map<int, EventQuestions> initialFields = {};

  /// Fields that saving in Firestore.
  final Map<int, EventQuestions> customFields = {};

  //List for UI
  List<EventQuestions> customFieldsList =
      []; //Crate one variable for UI and firestore

  /// Constructor: initializes the document name and default fields.
  SetQuestionsController() {
    firestoreServices = Get.find<FirestoreServices>();

    // Add fields from StaticData
    //Creates initial fields for new event from static data
    StaticData.guestProfileFields.forEach((groupId, fields) {
      fields.forEach((fieldName, inputType) {
        initialFields.addEntries([
          createGuestFieldConfig(
            fieldName: fieldName,
            inputType: inputType,
            groupId: groupId,
          ),
        ]);
      });
    });
  }

  /// Initializes the custom fields.
  /// If the Firestore database has saved fields, those are used.
  /// Otherwise, it falls back to the default initial fields.
  Future<void> initializeFields() async {
    _nextId = 0;
    customFields.clear();

    print("Initialisation Started");
    String eventId = hostController.selectedEvent.value!.eventId!;
    customFields.clear();
    try {
      final fetchedFields =
          await firestoreServices.fetchAllSetQuestions(eventId);
      for (var field in fetchedFields) {
        customFields.addAll(Map.fromEntries([
          createGuestFieldConfig(
            fieldName: field.fieldName,
            groupId: field.groupId,
            inputType: field.inputType,
          ),
        ]));
      }
      print('Initialised from firestore');
    } catch (e) {
      // If fetch fails, fallback to default fields.
      customFields.addAll(initialFields);
      print('Initialised by default');
    }
    // customFieldsList.value = customFields.values.toList();
    customFieldsList = customFields.values.toList();
    isLoading.value = false;
  }

  /// Adds an empty guest field to both the map and list.
  /// Returns the index where the field was added.
  int addFieldToList() {
    // Create and add to map
    final newField = createGuestFieldConfig();
    customFields[newField.key] = newField.value;

    // Add to list and return the index
    final index = customFieldsList.length;
    customFieldsList.add(newField.value);

    return index;
  }

  /// Removes a field from the customFieldsList and returns it.
  EventQuestions removeFieldFromList(int index) {
    final removedField = customFieldsList.removeAt(index);
    return removedField;
  }

  /// Removes a field from customFields and disposes its text controller.
  void removeGuestField(int id) {
    customFields[id]?.disposeGuestProfileFieldConfigControllers();
    customFields.remove(id);
  }

  /// Disposes all text editing controllers in customFields.
  /// Should be called when the controller is no longer needed.
  void disposeAllFieldControllers() {
    customFields.forEach(
      (key, value) => value.disposeGuestProfileFieldConfigControllers(),
    );
  }

  /// Validates and saves the current state of customFields to Firestore.
  /// Returns true if saving was successful.
  Future<bool> saveGuestFields() async {
    String eventId = hostController.selectedEvent.value!.eventId!;
    try {
      print('validation started');
      validateFields();
      print('validation end');
      await firestoreServices.saveSetQuestions(
          customFields.values.toList(), eventId);
      disposeAllFieldControllers();
      return true;
    } catch (e) {
      print("Error while saving guest fields: $e");
      return false;
    }
  }

  /// Creates a new field config (optionally with predefined values).
  /// Returns a MapEntry that can be added to a field map.
  MapEntry<int, EventQuestions> createGuestFieldConfig({
    String? fieldName,
    String? groupId,
    InputType? inputType,
  }) {
    final id = _nextId;
    final newField = EventQuestions(
      fieldName: fieldName,
      groupId: groupId,
      inputType: inputType,
      id: id,
    );
    _nextId++;
    return MapEntry(id, newField);
  }

  /// Validates all guest fields in customFields.
  /// Ensures no empty names, all inputTypes are set, and names are unique.
  void validateFields() {
    // final uniqueNames = <String>{};
    for (final field in customFields.values) {
      if (field.fieldNameController.text.trim().isEmpty) {
        throw Exception("Name field name cannot be empty");
      }
      if (field.groupIdController.text.trim().isEmpty) {
        throw Exception("Group ID field name cannot be empty");
      }
      if (field.inputType == null) {
        throw Exception("Input type cannot be null for a field.");
      }
      // if (uniqueNames.contains(field.fieldName)) {
      //   print('Duplicate fieldname');
      //   throw Exception("Duplicate field name: ${field.fieldName}");
      // }
      // uniqueNames.add(field.fieldName!);
    }
  }
}
