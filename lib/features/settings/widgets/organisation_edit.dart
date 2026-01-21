import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    final organisationController = Get.find<OrganisationController>();
    final isPhone = ScreenSize.isPhone(context);

    if (isPhone) {
      return Padding(
        padding: AppPadding.all(context, paddingType: Sizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionCard(
              title: 'Profile',
              subtitle: 'Update logo and account info',
              child: ProfilePhotoSection(controller: controller),
            ),
            AppSpacing.verticalSm(context),
            _SectionCard(
              title: 'Organisation',
              subtitle: 'Company details and preferences',
              child: OrganisationInfoFormSection(
                controller: controller,
                organisationController: organisationController,
              ),
            ),
            AppSpacing.verticalSm(context),
            _SectionCard(
              title: 'Security',
              subtitle: 'Change your password',
              child: ChangePasswordSection(controller: controller),
            ),
          ],
        ),
      );
    }

    // ✅ Desktop / Tablet: 2-column grid with clean divider
    return Padding(
      padding: AppPadding.all(context, paddingType: Sizes.md),
      child: LayoutBuilder(
        builder: (context, c) {
          final isTablet = ScreenSize.isTablet(context);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              SizedBox(
                width: isTablet ? 340 : 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionCard(
                      title: 'Profile',
                      subtitle: 'Update logo and account info',
                      child: ProfilePhotoSection(controller: controller),
                    ),
                    AppSpacing.verticalSm(context),
                    _SectionCard(
                      title: 'Security',
                      subtitle: 'Change your password',
                      child: ChangePasswordSection(controller: controller),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 18),

              // Divider (subtle)
              Container(
                width: 1,
                height: 680,
                color: const Color(0xFFE5E7EB),
              ),

              const SizedBox(width: 18),

              // Right column (form)
              Expanded(
                child: _SectionCard(
                  title: 'Organisation',
                  subtitle: 'Company details and preferences',
                  child: OrganisationInfoFormSection(
                    controller: controller,
                    organisationController: organisationController,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF111827),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
