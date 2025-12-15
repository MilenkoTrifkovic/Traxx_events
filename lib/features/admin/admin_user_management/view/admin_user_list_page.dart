import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/global_controllers/users_and_roles_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/controllers/admin_user_list_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/widgets/role_management_popup_popup.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/widgets/user_card.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/loader.dart';

class AdminUserListPage extends StatelessWidget {
  AdminUserListPage({super.key});

  final AdminUserListController controller = Get.put(AdminUserListController());
  final globalController = Get.find<UsersAndRolesController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  decoration: BoxDecoration(
                    color: globalController.usersWithRoles.isNotEmpty
                        ? AppColors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        _buildMainSection(),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainSection() {
    return Obx(() {
      final list = globalController.usersWithRoles;

      if (list.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView.builder(
        shrinkWrap: true, // ←
        physics: const NeverScrollableScrollPhysics(), // ←
        itemCount: list.length,
        itemBuilder: (context, index) {
          final user = list[index];
          return Padding(
            padding: AppPadding.bottom(context, paddingType: Sizes.xxs),
            child: UserCard(
              onEdit: () {
                controller.updateRoleAndEmail(list[index]);
                showDialog(
                  context: context,
                  builder: (context) {
                    return RoleManagementPopup(
                      isEditMode: true,
                      controller: controller,
                    );
                  },
                ).then(
                  (value) async {
                    if (value != null && value is bool && value) {
                      try {
                        showLoadingIndicator();
                        await controller.updateUser(
                            userId: list[index].userId!);
                      } on Exception {
                      } finally {
                        hideLoadingIndicator();
                      }
                    } else {}
                  },
                );
                // globalController.updateUser(user);
              },
              onDelete: () {
                globalController.deleteUser(user.userId!);
              },
              user: user,
            ),
          );
        },
      );
    });
  }
}
