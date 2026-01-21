import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/settings/controllers/settings_screen_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/features/settings/widgets/organisation_edit.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/loader.dart';

class SettingsPage extends StatelessWidget {
  SettingsPage({super.key});

  // instantiate controller (uses Get.find internally)

  final OrganisationController organisationController =
      Get.find<OrganisationController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show loading indicator while organisation is being initialized
      if (organisationController.isInitialized.value == false) {
        showLoadingIndicator();
        return Center(child: Container());
      }
      // Check if organisation data is null
      else if (organisationController.organisation.value == null) {
        hideLoadingIndicator();
        return Center(
          child: AppText.styledBodyMedium(
            context,
            'Page not available. Please try again later.',
          ),
        );
      }
      // Organisation data is available, build the content
      // Controller depends on organisation being loaded
      return _buildContent(context);
    });
  }

  Widget _buildContent(BuildContext context) {
    hideLoadingIndicator();
    final SettingsScreenController controller = SettingsScreenController();

    final w = MediaQuery.sizeOf(context).width;
    final outerPad = w < 600 ? 14.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.all(outerPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: OrganisationEdit(controller: controller),
          ),
        ),
      ),
    );
  }
}
