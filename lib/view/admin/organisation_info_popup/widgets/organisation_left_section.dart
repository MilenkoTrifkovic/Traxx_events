import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/organisation_info_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/constantsOld.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class OrganisationLeftSection extends StatelessWidget {
  const OrganisationLeftSection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OrganisationInfoController>();

    return SizedBox(
      width: 424,
      child: Container(
        color: AppColors.fofofo,
        child: Padding(
          padding: AppPadding.all(context, paddingType: Sizes.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Section
              Container(
                height: 92,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: 37,
                  child: Image.asset(
                    ConstantsOld.lightLogo,
                    height: 37,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Steps Section
              Expanded(
                child: ListView.builder(
                  itemCount: controller.totalSteps,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: AppPadding.only(
                        context,
                        paddingType: Sizes.md,
                        bottom: true,
                      ),
                      child: _buildStepCard(context, controller, index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepCard(
      BuildContext context, OrganisationInfoController controller, int index) {
    final step = controller.steps[index];

    return Obx(() {
      // final isActive = controller.isStepActive(index);
      // final isCompleted = controller.isStepCompleted(index);
      final isPending = controller.isStepPending(index);

      return GestureDetector(
        // onTap: () => controller.goToStep(index),
        child: SizedBox(
          width: 304,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon - aligned to the left
              Icon(
                _getStepIcon(index),
                color:
                    isPending ? AppColors.textMuted : AppColors.primaryAccent,
                size: 24,
              ),
              SizedBox(width: AppSpacing.xs(context)), // 8px horizontal spacing
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.styledBodyMedium(
                      context,
                      step.title,
                      weight: AppFontWeight.semiBold,
                      color: isPending ? AppColors.textMuted : Colors.black,
                    ),
                    const SizedBox(height: 4),
                    AppText.styledBodyMedium(
                      context,
                      step.description,
                      color:
                          isPending ? AppColors.textMuted : AppColors.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  IconData _getStepIcon(int index) {
    switch (index) {
      case 0:
        return Icons.badge_outlined; // Sales Representative
      case 1:
        return Icons.location_on_outlined; // Location & Time
      case 2:
        return Icons.restaurant_outlined; // Restaurant Info
      default:
        return Icons.circle_outlined;
    }
  }
}
