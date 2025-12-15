import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/organisation_info_controller.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/view/admin/organisation_info_popup/widgets/organisation_left_section.dart';
import 'package:traxx_wepapp/view/admin/organisation_info_popup/widgets/organisation_right_section.dart';
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
    // Get or create the controller instance - this ensures we get the same instance everywhere
    controller = Get.put(OrganisationInfoController(), permanent: true);

    // Initialize snackbar controller once in initState
    final snackbarController = Get.find<SnackbarMessageController>();

    // Watch for error messages and show snackbar
    ever(controller.errorMessage, (String? errorMessage) {
      if (errorMessage != null && errorMessage.isNotEmpty && mounted) {
        snackbarController.showErrorMessage(errorMessage);
        // Clear the error message after showing it
        controller.clearErrorMessage();
      }
    });

    // Watch for successful save and redirect to dashboard
    // ever(controller.shouldRedirectToDashboard, (bool shouldRedirect) {
    //   if (shouldRedirect && mounted) {
    //     print('ever is triggered in navigation to dashboard');
    //     hideLoadingIndicator();
    //     pushAndRemoveAllRoute(AppRoute.hostEvents, context);
    //   }
    // });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      child: Center(
        child: SizedBox(
          width: 1024,
          // height: 864,
          child: Row(
            children: [
              // Left Section
              if (ScreenSize.isDesktop(context) == true)
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
