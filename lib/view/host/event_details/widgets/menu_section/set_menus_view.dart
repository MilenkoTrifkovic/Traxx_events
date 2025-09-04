import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/host_controllers/menu_controllers/menu_controllers_manager.dart';
import 'package:traxx_wepapp/controller/host_controllers/menu_controllers/set_menus_controller.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/constants.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/view/host/event_details/widgets/menu_section/widgets/menu_form.dart';
import 'package:traxx_wepapp/widgets/buttons/styled_back_button.dart';

class SetMenusView extends StatefulWidget {
  const SetMenusView({super.key});

  @override
  State<SetMenusView> createState() => _SetMenusViewState();
}

class _SetMenusViewState extends State<SetMenusView> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ScrollController _scrollController = ScrollController();

  final MenuControllersManager menuControllersManager =
      Get.put(MenuControllersManager());
  final SetMenusController setMenusController = Get.put(SetMenusController());

  @override
  void initState() {
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
      child: Padding(
        padding: AppPadding.all(context, paddingType: Sizes.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StyledBackButton(),
                AppText.styledBodySmall(context, 'List of menu items:',
                    family: Constants.font2,
                    weight: FontWeight.bold,
                    overflow: TextOverflow.fade),
                AppSpacing.verticalXs(context)
              ],
            ),
            Obx(
              () {
                return setMenusController.isLoading.value
                    ? Center(
                        child: CircularProgressIndicator(),
                      )
                    : Expanded(
                        child: AnimatedList(
                          padding:
                              AppPadding.bottom(context, paddingType: Sizes.md),
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
                      );
              },
            ),
            AppSpacing.verticalMd(context),
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
                final index = setMenusController.addMenuItem();
                _listKey.currentState?.insertItem(index);

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
      ),
    );
  }
}
