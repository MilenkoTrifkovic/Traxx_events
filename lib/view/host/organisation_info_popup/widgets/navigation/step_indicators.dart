import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/host_controllers/organisation_info_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

class StepIndicators extends StatelessWidget {
  final OrganisationInfoController controller;

  const StepIndicators({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            controller.totalSteps,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: controller.isStepActive(index) ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: controller.isStepActive(index) ||
                        controller.isStepCompleted(index)
                    ? AppColors.primary
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ));
  }
}
