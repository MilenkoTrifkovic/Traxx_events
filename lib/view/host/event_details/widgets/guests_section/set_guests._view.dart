import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/host_controllers/guests_controllers/set_guests_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/view/host/event_details/widgets/guests_section/widgets/guest_animated_list.dart';
import 'package:traxx_wepapp/view/host/event_details/widgets/guests_section/widgets/guest_form.dart';
import 'package:traxx_wepapp/widgets/buttons/styled_back_button.dart';

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

  final SetGuestsController setGuestsController =
      Get.put(SetGuestsController());

  @override
  void initState() {
    setGuestsController.initializeGuestList();
    super.initState();
  }

  @override
  void dispose() {
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
    Timer(Duration(seconds: 3), () {
      if (mounted) {
        _itemColors.remove(index);
      }
    });
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
