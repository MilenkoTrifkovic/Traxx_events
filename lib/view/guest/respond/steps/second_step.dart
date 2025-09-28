import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/guest_controller.dart/respond_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/view/guest/respond/steps/widgets/menu_form.dart';
import 'package:traxx_wepapp/view/guest/respond/steps/widgets/response_form.dart';

class SecondStepContent extends StatelessWidget {
  final Function(Function) validateForm;
  final Event event;
  final RespondController respondController;
  const SecondStepContent(
      {super.key,
      required this.validateForm,
      required this.respondController,
      required this.event});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppPadding.horizontal(context, paddingType: Sizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            return ExpansionPanelList(
              expansionCallback: (panelIndex, isExpanded) {
                // Handle expansion logic here if needed
                respondController.changeExpansionState(index: panelIndex);
              },
              children: [
                for (var i = 0; i < respondController.allResponses.length; i++)
                  ExpansionPanel(
                      canTapOnHeader: true,
                      isExpanded: respondController.allResponses[i].isExpanded,
                      headerBuilder: (context, isExpanded) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText.styledBodyMedium(
                              context,
                              respondController.allResponses[i].guestId !=
                                      null //only primary guest has guestId
                                  ? 'You'
                                  : 'Companion',
                              weight: FontWeight.bold,
                            ),
                          ],
                        );
                      },
                      body: Column(
                        children: [
                          GuestMenuForm(
                            respondController: respondController,
                            responseId: i,
                            event: event,
                          ),
                          ResponseForm(
                            registerValidation: validateForm,
                            // formKey: formKey,
                            guestResponse: respondController.allResponses[i],
                          ),
                        ],
                      ))
              ],
            );
          }),
        ],
      ),
    );
  }
}
