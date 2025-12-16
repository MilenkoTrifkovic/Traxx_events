import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/host_controller.dart';
import 'package:traxx_wepapp/models/event_questions.dart';
import 'package:traxx_wepapp/services/firestore_services/firestore_services.dart';
import 'package:traxx_wepapp/utils/enums/input_type.dart';
import 'package:traxx_wepapp/utils/static_data.dart';

class SetQuestionsController {
  RxBool isLoading = true.obs;
  final HostController hostController =
      Get.find<HostController>(); //new approach
  late final FirestoreServices firestoreServices;
  int _nextId = 0;
  final Map<int, EventQuestions> initialFields = {};

  /// Fields that saving in Firestore.
  final Map<int, EventQuestions> customFields = {};

  //List for UI
  List<EventQuestions> customFieldsList = [];
  SetQuestionsController() {
    firestoreServices = Get.find<FirestoreServices>();
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

  Future<void> initializeFields() async {
    _nextId = 0;
    customFields.clear();

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

  int addFieldToList() {
    // Create and add to map
    final newField = createGuestFieldConfig();
    customFields[newField.key] = newField.value;

    // Add to list and return the index
    final index = customFieldsList.length;
    customFieldsList.add(newField.value);

    return index;
  }

  EventQuestions removeFieldFromList(int index) {
    final removedField = customFieldsList.removeAt(index);
    return removedField;
  }

  /// Removes a field from customFields and disposes its text controller.
  void removeGuestField(int id) {
    customFields[id]?.disposeGuestProfileFieldConfigControllers();
    customFields.remove(id);
  }

  void disposeAllFieldControllers() {
    customFields.forEach(
      (key, value) => value.disposeGuestProfileFieldConfigControllers(),
    );
  }

  Future<bool> saveGuestFields() async {
    String eventId = hostController.selectedEvent.value!.eventId!;
    try {
      validateFields();
      await firestoreServices.saveSetQuestions(
          customFields.values.toList(), eventId);
      disposeAllFieldControllers();
      return true;
    } catch (e) {
      print("Error while saving guest fields: $e");
      return false;
    }
  }

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

  void validateFields() {
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
    }
  }
}
