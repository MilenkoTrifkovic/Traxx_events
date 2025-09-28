import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/controller/host_controllers/create_edit_event_controller.dart';
import 'package:traxx_wepapp/controller/host_controllers/host_controller.dart';
import 'package:traxx_wepapp/utils/styled_buttons/styled_text_button.dart';
import 'package:traxx_wepapp/forms/create_event/event_form_state.dart';

/// Widget for handling event cover image upload.
/// Shows an upload button initially, then displays the selected image
/// with the ability to change it by tapping.
class CoverImageUpload extends StatefulWidget {
  const CoverImageUpload({super.key});

  @override
  State<CoverImageUpload> createState() => _CoverImageUploadState();
}

class _CoverImageUploadState extends State<CoverImageUpload> {
  /// Controller for handling image upload logic
  final CreateEditEventController _createEventController =
      Get.find<CreateEditEventController>();
  final HostController _hostController = Get.find<HostController>();
  final EventListController _eventListController =
      Get.find<EventListController>();

  /// Form state for storing the uploaded image
  final EventFormState formState = Get.find<EventFormState>();

  /// Currently selected cover image file
  XFile? coverImage;

  @override
  Widget build(BuildContext context) {
    if (_hostController.isEditingEvent.value &&
        _hostController.selectedEvent.value!.coverImageUrl != null &&
        // this is an URL _eventListController.selectedEvent.value!.coverImageUrl != null &&
        coverImage == null) {
      print(
          'this is an URL ${_hostController.selectedEvent.value?.coverImageDownloadUrl}');
      return Column(
        children: [
          GestureDetector(
            onTap: () async {
              coverImage = await _createEventController.loadCoverImage();
              setState(() {});
            },
            child: Container(
              width: 400,
              height: 225,
              color: Colors.grey[200],
              child: FittedBox(
                fit: BoxFit.contain,
                // fit: BoxFit.fill,
                child: Image(
                  image: Image.network(
                    // 'https://firebasestorage.googleapis.com/v0/b/traxx-e1232.firebasestorage.app/o/uploads%2F1756054157689.jpg?alt=media&token=7a05ff34-eeb1-4c64-8cc4-7f82a07277ce'
                    // _eventListController
                    _hostController
                            .selectedEvent.value?.coverImageDownloadUrl ??
                        '',
                  ).image,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
    }
    return Column(
      children: [
        coverImage == null
            ? StyledTextButton(
                onPressed: () async {
                  coverImage = await _createEventController.loadCoverImage();
                  setState(() {});
                },
                text: 'Upload Cover Image',
              )
            : GestureDetector(
                onTap: () async {
                  coverImage = await _createEventController.loadCoverImage();
                  setState(() {});
                },
                child: Container(
                  width: 400,
                  height: 225,
                  color: Colors.grey[200],
                  child: FittedBox(
                    fit: BoxFit.contain,
                    // fit: BoxFit.fill,
                    child: Image(image: Image.network(coverImage!.path).image),
                  ),
                ),
              ),
        const SizedBox(height: 16),
      ],
    );
  }
}
