import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/admin_event_details_controller.dart';
import 'package:traxx_wepapp/controller/admin_controllers/admin_event_details_controllers/menu_panel_controller.dart';
import 'package:traxx_wepapp/view/admin/event_details/widgets/menu_panel_item.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';

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
    // Use controller initialized in initState

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        const minWidth = 200.0;
        const maxColumns = 5;

        int columns = (screenWidth / minWidth).floor();
        columns = columns.clamp(1, maxColumns);

        final itemWidth = screenWidth / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          // children: List.generate(4, (index) {
          children:
              List.generate(controller.availableMenus.value.length, (index) {
            return MenuPanelItem(
              title: controller.availableMenus.value.keys.elementAt(index).name,
              icon: controller.availableMenus.value.keys.elementAt(index).icon,
              buttonText:
                  'Add ${controller.availableMenus.value.keys.elementAt(index).name.toString().capitalize}',
              itemWidth: itemWidth,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AppDialog(
                      content: Container(
                        color: Colors.red,
                      ),
                    );
                  },
                );
              },
            );
          }),
        );
      },
    );
  }
}
