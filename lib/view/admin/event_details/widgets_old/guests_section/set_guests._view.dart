import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/guests_controllers/set_guests_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/utils/styled_buttons/styled_text_button.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets_old/guests_section/widgets/guest_animated_list.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets_old/guests_section/widgets/guest_form.dart';
import 'package:traxx_wepapp/widgets/buttons/styled_back_button.dart';
import 'package:traxx_wepapp/widgets/dialogs/dialogs.dart';

/// A view for managing event guests that provides functionality for:
/// - Viewing, adding, and removing guests
/// - Form-based guest entry with validation
/// - Animated list with automatic sorting by name
/// - Visual feedback for guest additions
class SetGuestsView extends StatefulWidget {
  const SetGuestsView({super.key});

  @override
  State<SetGuestsView> createState() => _SetGuestsViewState();
}

class _SetGuestsViewState extends State<SetGuestsView> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final ScrollController _scrollController = ScrollController();
  final List<Timer> _timers = [];

  late final SetGuestsController setGuestsController;

  @override
  void initState() {
    super.initState();
    setGuestsController = Get.put(SetGuestsController());
    setGuestsController.initializeGuestList();
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        ever(
          setGuestsController.errorMessage,
          (callback) => Dialogs.showInformationDialog(context, callback),
        );
      },
    );
  }

  @override
  void dispose() {
    for (var t in _timers) {
      t.cancel();
    }
    _scrollController.dispose();
    Get.delete<SetGuestsController>();
    super.dispose();
  }

  /// Map for storing item colors by index
  /// Used to temporarily change the color of a guest item when it's added
  final Map<int, Color> _itemColors = {};
  void _addColor(int index) {
    // Prevent duplicate color assignments
    if (_itemColors.containsKey(index)) {
      return;
    }
    _itemColors[index] = AppColors.primaryContainer(context);
    // Removes a color after 3 seconds
    final timer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        _itemColors.remove(index);
      }
    });
    _timers.add(timer);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.all(context, paddingType: Sizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StyledBackButton(),
                  //Displays current guest count and limit Eg. Guests: 26 / 50
                  Obx(() {
                    int guestCount =
                        setGuestsController.currentGuestCount.value;
                    int guestLimit = setGuestsController.guestLimit.value;
                    return AppText.styledBodyLarge(
                        context, 'Guests: $guestCount / $guestLimit');
                  }),
                  StyledTextButton(
                      onPressed: () async {
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['csv', 'xlsx'],
                        );
                        if (result == null) {
                          // User canceled the picker
                          return;
                        }
                        final file = result.files.first;
                        setGuestsController.addGuestFromCsvXlsX(file);
                      },
                      text: 'Upload CSV/XLS')
                ],
              ),
              AppSpacing.verticalXs(context)
            ],
          ),
          Obx(
            () {
              return setGuestsController.isLoading.value
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : GuestAnimatedList(
                      listKey: _listKey,
                      scrollController: _scrollController,
                      colors: _itemColors);
            },
          ),
          AppSpacing.verticalMd(context),
          GuestForm(
            addColor: _addColor,
            listKey: _listKey,
            scrollController: _scrollController,
          ),
        ],
      ),
    );
  }
}
