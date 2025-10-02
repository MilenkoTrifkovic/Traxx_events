import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/guest_controller.dart/respond_controller.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/view/guest/widgets/responses_table.dart';

class ThirdStepContent extends StatelessWidget {
  final RespondController respondController;
  const ThirdStepContent({super.key, required this.respondController});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.radius(context, size: Sizes.sm),
            side: BorderSide(
              color: AppColors.primary(context).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: AppPadding.all(context, paddingType: Sizes.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  final responses =
                      respondController.getAllResponsesAsTableRows();
                  //Content
                  return ResponsesTable(responses: responses);
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
