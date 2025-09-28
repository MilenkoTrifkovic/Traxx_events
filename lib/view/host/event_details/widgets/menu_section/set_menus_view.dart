import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/host_controllers/menu_controllers/menu_controllers_manager.dart';
import 'package:traxx_wepapp/controller/host_controllers/menu_controllers/set_menus_controller.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/event_type.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/view/host/event_details/widgets/menu_section/widgets/menu_form.dart';
import 'package:traxx_wepapp/view/host/event_details/widgets/menu_section/widgets/selectable_category_chooser.dart';
import 'package:traxx_wepapp/widgets/page_header.dart';
import 'package:traxx_wepapp/widgets/section_devider.dart';

/// A widget that provides an interface for managing event menus.
///
/// This widget allows hosts to:
/// - Create and delete menu items
/// - Select menu categories for plated service events
/// - Add images and details to menu items
/// - Save menu changes to Firestore
///
/// Uses [AnimatedList] for smooth menu item additions/removals and
/// integrates with [SetMenusController] for state management.
class SetMenusView extends StatefulWidget {
  const SetMenusView({
    super.key,
  });

  @override
  State<SetMenusView> createState() => _SetMenusViewState();
}

class _SetMenusViewState extends State<SetMenusView> {
  // Key for managing animated list insertions and removals
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  // Key for form validation across all menu items
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  // Controller for scrolling to newly added items
  final ScrollController _scrollController = ScrollController();

  // Manages text controllers for all menu items
  final MenuControllersManager menuControllersManager =
      Get.put(MenuControllersManager());
  // Main controller for menu operations and state management
  late final SetMenusController setMenusController;

  @override
  void initState() {
    setMenusController = Get.put(SetMenusController());
    setMenusController.initializeMenus();
    super.initState();
  }

  @override
  void dispose() {
    menuControllersManager.disposeAll();
    Get.delete<MenuControllersManager>();
    Get.delete<SetMenusController>();
    super.dispose();
  }

  /// Handles removal of menu items with animation.
  ///
  /// Deletes the item from the controller and shows a removal animation
  /// using AnimatedList. The removed item remains visible during the animation.
  void _removeItem(int index) {
    final removedItem = setMenusController.deleteMenuItem(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => MenuForm(
        index: index,
        onPressed: _removeItem,
        item: removedItem,
        animation: animation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Menus',
              ),
              AppSpacing.verticalXs(context)
            ],
          ),
          // Main content area with reactive updates for menu changes
          Obx(
            () {
              final categories = setMenusController.menuCategories;
              return setMenusController.isLoading.value
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          //Only for platted meals could be selected
                          if (setMenusController
                                  .selectedEvent.value.serviceType ==
                              ServiceType.plated)
                            SelectableCategoryChooser(
                                categories: categories,
                                setMenusController: setMenusController),
                          AppSpacing.verticalXs(context),
                          SectionDivider(
                            thickness: 0.75,
                            height: 0,
                          ),
                          //Menu Items
                          Expanded(
                            child: AnimatedList(
                              padding: AppPadding.bottom(context,
                                  paddingType: Sizes.md),
                              controller: _scrollController,
                              shrinkWrap: true,
                              key: _listKey,
                              initialItemCount: setMenusController.menus.length,
                              itemBuilder: (context, index, animation) {
                                return MenuForm(
                                    index: index,
                                    item: setMenusController.menus[index],
                                    animation: animation,
                                    onPressed: _removeItem);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
            },
          ),
          AppSpacing.verticalMd(context),
          //Create and Save Buttons
          //Create Button
          ElevatedButton.icon(
            icon: Icon(Icons.add),
            label: AppText.styledBodyMedium(context, 'Create New Menu'),
            style: ElevatedButton.styleFrom(
              padding: AppPadding.vertical(context, paddingType: Sizes.sm),
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.radius(context, size: Sizes.sm),
              ),
            ),
            onPressed: () {
              // Add new menu item and animate its insertion
              final index = setMenusController.addMenuItem();
              _listKey.currentState?.insertItem(index);

              // Scroll to the newly added item after the frame is rendered
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              });
            },
          ),
          AppSpacing.verticalXs(context),
          //Save Button
          ElevatedButton.icon(
            icon: Icon(Icons.save),
            label: AppText.styledBodyMedium(context, 'Save'),
            style: ElevatedButton.styleFrom(
              padding: AppPadding.vertical(context, paddingType: Sizes.sm),
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.radius(context, size: Sizes.sm),
              ),
            ),
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                bool success = await setMenusController.saveMenus();
                if (success) {
                  popRoute(context);
                } else {
                  SnackBarUtils.showError(context,
                      "Some required fields are missing. Please complete all required fields.");
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
