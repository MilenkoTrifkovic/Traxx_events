import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/host_controllers/organisation_info_controller.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/view/host/organisation_info_popup/widgets/organisation_left_section.dart';
import 'package:traxx_wepapp/view/host/organisation_info_popup/widgets/organisation_right_section.dart';
import 'package:traxx_wepapp/widgets/background_scaffold.dart';

class OrganisationInfoPopupView extends StatefulWidget {
  const OrganisationInfoPopupView({super.key});

  @override
  State<OrganisationInfoPopupView> createState() =>
      _OrganisationInfoPopupViewState();
}

class _OrganisationInfoPopupViewState extends State<OrganisationInfoPopupView> {
  late final OrganisationInfoController controller;

  @override
  void initState() {
    super.initState();
    // Initialize the controller
    controller = Get.put(OrganisationInfoController());

    // Watch for error messages and show snackbar
    ever(controller.errorMessage, (String? errorMessage) {
      if (errorMessage != null && errorMessage.isNotEmpty && mounted) {
        SnackBarUtils.showError(context, errorMessage);
        // Clear the error message after showing it
        controller.clearErrorMessage();
      }
    });

    // Watch for successful save and redirect to dashboard
    ever(controller.shouldRedirectToDashboard, (bool shouldRedirect) {
      if (shouldRedirect && mounted) {
        hideLoadingIndicator();
        pushAndRemoveAllRoute(AppRoute.hostEvents, context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      child: Center(
        child: SizedBox(
          width: 1024,
          // height: 864,
          child: const Row(
            children: [
              // Left Section
              OrganisationLeftSection(),
              // Right Section
              OrganisationRightSection(),
            ],
          ),
        ),
      ),
    );
  }
}
