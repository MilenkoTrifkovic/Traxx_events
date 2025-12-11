import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/settings/controllers/settings_screen_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/widgets/section_devider.dart';
import 'profile_photo_section.dart';
import 'change_password_section.dart';
import 'organisation_info_form_section.dart';

class OrganisationEdit extends StatelessWidget {
  final SettingsScreenController controller;
  const OrganisationEdit({super.key, required this.controller});

  Widget buildPhoneLayout(
      BuildContext context, OrganisationController organisationController) {
    return Padding(
      padding: AppPadding.all(context, paddingType: Sizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile photo at top
          Padding(
            padding: AppPadding.horizontal(context, paddingType: Sizes.md),
            child: ProfilePhotoSection(controller: controller),
          ),
          AppSpacing.verticalXxs(context),
          SectionDivider(),
          AppSpacing.verticalXxs(context),
          // Organisation info form next
          Padding(
            padding: AppPadding.horizontal(context, paddingType: Sizes.md),
            child: OrganisationInfoFormSection(
              controller: controller,
              organisationController: organisationController,
            ),
          ),
          AppSpacing.verticalXxs(context),
          SectionDivider(),
          AppSpacing.verticalXxs(context),
          // Change password at bottom
          Padding(
            padding: AppPadding.horizontal(context, paddingType: Sizes.md),
            child: ChangePasswordSection(controller: controller),
          ),
        ],
      ),
    );
  }

  Widget buildDesktopTabletLayout(
      BuildContext context, OrganisationController organisationController) {
    return Padding(
      padding: AppPadding.all(context, paddingType: Sizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column with a right border to simulate a divider
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    // color: Colors.red,
                    border: Border(
                      right: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding:
                        AppPadding.horizontal(context, paddingType: Sizes.md),
                    child: Column(
                      // crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ProfilePhotoSection(controller: controller),
                        ChangePasswordSection(controller: controller),
                      ],
                    ),
                  ),
                ),
              ),
              // Right column (no left border) — keep divider only on left Expanded
              Expanded(
                flex: ScreenSize.isDesktop(context) ? 5 : 3,
                child: Transform.translate(
                  offset: const Offset(-1, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.textMuted,
                          width: 1.0,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding:
                          AppPadding.horizontal(context, paddingType: Sizes.md),
                      child: OrganisationInfoFormSection(
                        controller: controller,
                        organisationController: organisationController,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final organisationController = Get.find<OrganisationController>();

    // Return phone layout (column of three sections) when on small screens,
    // otherwise keep the existing row-based layout used for tablet/desktop.
    if (ScreenSize.isPhone(context)) {
      return buildPhoneLayout(context, organisationController);
    }

    return buildDesktopTabletLayout(context, organisationController);
  }
}
