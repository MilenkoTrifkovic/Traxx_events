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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
            color: AppColors.white,
            child: OrganisationEdit(controller: controller),
          ),
        ),
      ),
    );
  }
}
