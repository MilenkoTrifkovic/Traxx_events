import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/controllers/admin_guest_list_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/widgets/add_guest_popup.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/widgets/guest_card.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class GuestPanelBody extends StatelessWidget {
  GuestPanelBody({super.key});
  final AdminGuestListController controller =
      Get.find<AdminGuestListController>();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      // child: Text('GuestGuest list panel content goes here.'),
      child: _buildVenuesListSection(context, controller),
    );
  }

  Widget _buildVenuesListSection(
      BuildContext context, AdminGuestListController controller) {
    return Obx(() {
      if (controller.filteredGuests.isEmpty &&
          controller.guests.isEmpty &&
          !controller.isInitialized.value) {
        return SizedBox(
          // height: MediaQuery.of(context).size.height -
          //     200, // Give it most of the screen height
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        );
      }
      if (controller.filteredGuests.isEmpty &&
          controller.guests.isEmpty &&
          controller.isInitialized.value) {
        return SizedBox(
          // height: MediaQuery.of(context).size.height -
          //     200, // Give it most of the screen height
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: AppText.styledBodyMedium(context, 'List is empty.',
                color: AppColors.textMuted, weight: AppFontWeight.semiBold),
          ),
        );
      }

      return Padding(
        padding: AppPadding.bottom(context, paddingType: Sizes.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.filteredGuests.length,
              itemBuilder: (context, index) {
                final guest = controller.filteredGuests[index];
                return Padding(
                  padding: AppPadding.bottom(context, paddingType: Sizes.xxs),
                  // child: Text(guest.name),
                  // child: Text('dsadsada'),
                  child: GuestCard(
                      guest: guest,
                      onDelete: () {
                        // Call the delete method from the controller
                        // controller.removeGuest(guest.id);
                        controller.deleteGuest(guest.guestId!);
                      },
                      onTap: () {
                        // showDialog(context: context, builder: (context) {
                        //   return MenuDetailsDialog(menu: menuItem);
                        // });
                      },
                      onEdit: () {
                        print('Editing guest: ${guest.toString()}');
                        controller.updateAllFields(guest);
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AddGuestPopup(
                                controller: controller,
                                isEditMode: true,
                              );
                            }).then((value) {
                          controller.clearForm();
                        });
                      }),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
