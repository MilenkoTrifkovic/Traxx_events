import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:traxx_wepapp/controller/guest_controller.dart/respond_controller.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/styled_buttons/styled_text_button.dart';

class FirstStepContent extends StatelessWidget {
  final RespondController respondController;
  const FirstStepContent({super.key, required this.respondController});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.all(context, paddingType: Sizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.styledBodyMedium(
            weight: FontWeight.bold,
            color: AppColors.error(context),
            context,
            'Will you attend this event?',
          ),
          AppSpacing.verticalXs(context),
          Row(
            children: [
              //No Button
              Expanded(
                child: Obx(() => Badge(
                      backgroundColor: AppColors.error(context),
                      label: Icon(Icons.close,
                          size: 18, color: AppColors.onPrimary(context)),
                      isLabelVisible: respondController.badgeState.value < 0,
                      child: SizedBox(
                        width: double.infinity,
                        child: StyledTextButton(
                            isPrimary: false,
                            onPressed: () {
                              respondController
                                  .setPrimaryGuestAttendance(false);
                            },
                            text: 'No'),
                      ),
                    )),
              ),
              AppSpacing.horizontalMd(context),
              //Yes Button
              Expanded(
                child: Obx(() => Badge(
                      backgroundColor: AppColors.primaryContainer(context),
                      label: Icon(Icons.check,
                          size: 18, color: AppColors.primaryOld(context)),
                      isLabelVisible: respondController.badgeState.value > 0,
                      child: SizedBox(
                        width: double.infinity,
                        child: StyledTextButton(
                            backgroundColor: AppColors.success,
                            onPressed: () {
                              respondController.setPrimaryGuestAttendance(true);
                            },
                            text: 'Yes'),
                      ),
                    )),
              ),
            ],
          ),
          AppSpacing.verticalMd(context),
          Obx(() {
            // String message = respondController.primaryGuestWillAttend == true
            //     ? 'If you can’t attend, you can still add another guest to come in your place.'
            //     : 'If you can’t attend, you can still add another guest to come in your place and compaignons.';
            if (!respondController.primaryGuestWillAttend.value) {
              return Container();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // respondController.badgeState.value > 0
                //     ?
                AppText.styledBodyMedium(
                  weight: FontWeight.bold,
                  color: AppColors.error(context),
                  context,
                  'How many guests will you bring with you?',
                ),
                // : (respondController.badgeState.value == 0
                //     ? const SizedBox.shrink()
                //     : AppText.styledBodyMedium(
                //         weight: FontWeight.bold,
                //         color: AppColors.error(context),
                //         context,
                //         'If you can’t attend, you can still add another guest to come in your place.',
                //       )),
                if (respondController.badgeState.value > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          AppColors.primaryContainer(context).withOpacity(0.1),
                      // borderRadius: BorderRadius.circular(12),
                      borderRadius:
                          AppBorderRadius.radius(context, size: Sizes.sm),
                      border: Border.all(
                        color: AppColors.primaryOld(context).withOpacity(0.3),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      //Companions Dropdown
                      child: DropdownButton(
                        isExpanded: true,
                        value: respondController.companionsCount.toString(),
                        items: List.generate(
                          // respondController.primaryGuestWillAttend.value
                          //     ?
                          respondController.peopleAllowed,
                          //     :
                          // respondController.peopleAllowed + 1,
                          (index) => DropdownMenuItem(
                            value: index.toString(),
                            child: AppText.styledBodyMedium(
                                context,
                                index > 1
                                    ? '${index.toString()} guests'
                                    : '${index.toString()} guest'),
                          ),
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            respondController
                                .addCompanionsToAllResponses(int.parse(value));
                          }
                        },
                      ),
                    ),
                  )
              ],
            );
          }),
        ],
      ),
    );
  }
}
