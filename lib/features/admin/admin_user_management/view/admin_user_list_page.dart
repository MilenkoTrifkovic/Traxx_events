import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/global_controllers/users_and_roles_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/controllers/admin_user_list_controller.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/widgets/role_management_popup_popup.dart';
import 'package:traxx_wepapp/features/admin/admin_user_management/widgets/user_card.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/user_model.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/loader.dart';

class AdminUserListPage extends StatelessWidget {
  AdminUserListPage({super.key});

  final AdminUserListController controller = Get.put(AdminUserListController());
  final globalController = Get.find<UsersAndRolesController>();

  void _editUser(BuildContext context, dynamic user) {
    controller.updateRoleAndEmail(user);
    showDialog(
      context: context,
      builder: (_) => RoleManagementPopup(
        isEditMode: true,
        controller: controller,
      ),
    ).then((value) async {
      if (value == true) {
        try {
          showLoadingIndicator();
          await controller.updateUser(userId: user.userId!);
        } finally {
          hideLoadingIndicator();
        }
      }
    });
  }

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

      return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final isMobile = w < 900;

          // Helpers (safe)
          String title(UserModel u) => u.email;

          String subtitle(UserModel u) {
            // role.name is like "admin" -> make it "Admin"
            final r = u.role.name.trim();
            if (r.isEmpty) return '—';
            return r[0].toUpperCase() + r.substring(1);
          }

          // ✅ Mobile: container cards (no table)
          if (isMobile) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final user = list[index];

                return Padding(
                  padding: AppPadding.bottom(context, paddingType: Sizes.xxs),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _editUser(context, user),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title(user),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle(user),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () => _editUser(context, user),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.redAccent),
                            onPressed: () =>
                                globalController.deleteUser(user.userId!),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          // ✅ Desktop/tablet: DataTable with constrained cells (NO horizontal scrolling)
          const actionsW = 110.0; // fixed space for icons
          final nameW = (w - actionsW - 60).clamp(220.0, 9999.0);

          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowHeight: 48,
                  dataRowMinHeight: 56,
                  dataRowMaxHeight: 64,
                  horizontalMargin: 14,
                  columnSpacing: 12, // tighter

                  headingRowColor:
                      MaterialStateProperty.all(const Color(0xFFF3F4F6)),
                  headingTextStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                  dataTextStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),

                  border: const TableBorder(
                    top: BorderSide(color: Color(0xFFE5E7EB)),
                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    left: BorderSide(color: Color(0xFFE5E7EB)),
                    right: BorderSide(color: Color(0xFFE5E7EB)),
                    horizontalInside: BorderSide(color: Color(0xFFE5E7EB)),
                    verticalInside: BorderSide.none,
                  ),

                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Actions')),
                  ],

                  rows: list.map((user) {
                    return DataRow(
                      onSelectChanged: (_) => _editUser(context, user),
                      cells: [
                        DataCell(
                          SizedBox(
                            width: nameW,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title(user),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle(user),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: actionsW,
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _editUser(context, user),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: Colors.redAccent),
                                  onPressed: () =>
                                      globalController.deleteUser(user.userId!),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
