import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/controllers/admin_user_list_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/widgets/role_management_popup_popup.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminUserManagementHeader extends StatelessWidget {
  AdminUserManagementHeader({super.key});

  final AdminUserListController controller = AdminUserListController();
  final SnackbarMessageController snackbarMessageController =
      Get.find<SnackbarMessageController>();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = w < 600 ? 26.0 : (w < 1200 ? 32.0 : 40.0);
    final isMobile = w < 600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'User Management',
          style: GoogleFonts.poppins(
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),

        // ✅ keep button compact on mobile
        isMobile
            ? IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => RoleManagementPopup(controller: controller),
                  ).then((value) async {
                    if (value == true) {
                      try {
                        showLoadingIndicator();
                        await controller.submitForm();
                      } catch (_) {
                        snackbarMessageController
                            .showErrorMessage('Error creating user');
                      } finally {
                        hideLoadingIndicator();
                      }
                    }
                  });
                },
              )
            : AppPrimaryButton(
                icon: Icons.add,
                text: 'Add User',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => RoleManagementPopup(controller: controller),
                  ).then((value) async {
                    if (value == true) {
                      try {
                        showLoadingIndicator();
                        await controller.submitForm();
                      } catch (_) {
                        snackbarMessageController
                            .showErrorMessage('Error creating user');
                      } finally {
                        hideLoadingIndicator();
                      }
                    }
                  });
                },
              ),
      ],
    );
  }
}
