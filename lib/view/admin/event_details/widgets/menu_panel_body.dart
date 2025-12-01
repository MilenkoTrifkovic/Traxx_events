import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/admin_event_details_controller.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/menu_panel_controller.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/menu_panel_item.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/menu_selection_dialog.dart';

class MenuPanelBody extends StatefulWidget {
  final AdminEventDetailsController mainController;
  const MenuPanelBody({super.key, required this.mainController});

  @override
  State<MenuPanelBody> createState() => _MenuPanelBodyState();
}

class _MenuPanelBodyState extends State<MenuPanelBody> {
  late MenuPanelController controller;

  @override
  void initState() {
    super.initState();
    controller = MenuPanelController(widget.mainController);
    controller.populateAvailableMenus();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int columns;
          final screenWidth = constraints.maxWidth;

          if (ScreenSize.isPhone(context)) {
            columns = 2;
          } else {
            const minWidth = 200.0;
            const maxColumns = 5;

            columns = (screenWidth / minWidth).floor();
            columns = columns.clamp(1, maxColumns);
          }

          final itemWidth = screenWidth / columns;

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children:
                List.generate(controller.availableMenus.value.length, (index) {
              return MenuPanelItem(
                title:
                    controller.availableMenus.value.keys.elementAt(index).name,
                icon:
                    controller.availableMenus.value.keys.elementAt(index).icon,
                buttonText:
                    'Add ${controller.availableMenus.value.keys.elementAt(index).name.toString().capitalize}',
                itemWidth: itemWidth,
                onTap: () {
                  widget.mainController.syncSelectedMenusLists();
                  showDialog(
                    context: context,
                    builder: (context) {
                      return MenuSelectionDialog(
                        onRemoveMenuItem:
                            widget.mainController.removeMenuItemFromSelection,
                        category: controller.availableMenus.value.keys
                            .elementAt(index),
                        availableMenus1: widget.mainController.availableMenus,
                        selectedMenus:
                            // widget.mainController.selectedMenusFirestore,
                            widget.mainController.selectedMenusLocally,
                        onSelectionChanged: (selected) {},
                        selectNewMenuItem: (selected) {
                          widget.mainController
                              .addMenuItemToSelection(selected);
                        },
                        updateEvent: () async {
                          widget.mainController.updateEvent();
                        },
                      );
                    },
                  ).then(
                    (value) async {
                      if (value == true) {
                        showLoadingIndicator();
                        await widget.mainController
                            .updateEvent(); //Saving changes
                        hideLoadingIndicator();
                      } else {
                        widget.mainController
                            .syncSelectedMenusLists(); // CANCEL
                      }
                    },
                  );
                },
              );
            }),
          );
        },
      ),
    );
  }
}
