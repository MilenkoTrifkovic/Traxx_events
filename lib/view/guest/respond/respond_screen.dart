import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/guest_controller.dart/respond_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/styled_buttons/styled_text_button.dart';
import 'package:traxx_wepapp/view/guest/respond/steps/first_step.dart';
import 'package:traxx_wepapp/view/guest/respond/steps/second_step.dart';
import 'package:traxx_wepapp/view/guest/respond/steps/third_step.dart';

class RespondScreen extends StatefulWidget {
  // final String eventId;
  final Event event;
  const RespondScreen({
    super.key,
    required this.event,
  });

  @override
  State<RespondScreen> createState() => _RespondScreenState();
}

class _RespondScreenState extends State<RespondScreen> {
  final secondStepKey =
      GlobalKey(); //Allows scrolling to the top of the form when errror occurs
  bool _isControllerInitialized = false;
  late RespondController _respondController;

  @override
  void initState() {
    _initializeController();
    super.initState();
  }

  // This async function handles the loading process
  Future<void> _initializeController() async {
    final newController = await RespondController.create(widget.event.eventId!,
        widget.event.selectableCategories, widget.event.serviceType!);

    setState(() {
      _respondController = newController;
      _isControllerInitialized = true;
    });
  }

  @override
  void dispose() {
    Get.delete<RespondController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isControllerInitialized) {
      return Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return Obx(() {
        return Stepper(
          type: ScreenSize.isPhone(context)
              ? StepperType.horizontal
              : StepperType.vertical,
          currentStep: _respondController.currentStep.value,
          onStepContinue: _respondController.onStepContinue,
          onStepCancel: _respondController.onStepCancel,
          controlsBuilder: (context, details) {
            final isLastStep = details.currentStep == 2;

            return Padding(
              padding: AppPadding.vertical(context, paddingType: Sizes.sm),
              child: Row(
                children: [
                  if (details.currentStep > 0)
                    StyledTextButton(
                      onPressed: () {
                        details.onStepCancel!();
                      },
                      text: 'Back',
                      isPrimary: false,
                    ),
                  if (!isLastStep)
                    Obx(() => StyledTextButton(
                          onPressed: _respondController.nextButtonState.value
                              ? () {
                                  if (_respondController.currentStep.value ==
                                      1) {
                                    _respondController.changeExpansionState();

                                    // Validate the form in the second step
                                    if (_respondController.validateAll()) {
                                      details.onStepContinue!();
                                    } else {
                                      // Scroll to the top of the form if validation fails
                                      Scrollable.ensureVisible(
                                        secondStepKey.currentContext!,
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    }
                                  } else {
                                    details.onStepContinue!();
                                  }
                                }
                              : null,
                          text: 'Next',
                        )),
                  if (isLastStep)
                    StyledTextButton(
                      onPressed: () async {
                        await _respondController.submitAllResponses();
                        if (!mounted) return;

                        pushAndRemoveAllRoute(
                            AppRoute.guestEventDetails, context,
                            urlParam: widget.event.eventId);
                      },
                      text: 'Submit',
                    ),
                ],
              ),
            );
          },
          steps: [
            Step(
              title: _stepTitle(context, 'RSVP', 0),
              content: FirstStepContent(respondController: _respondController),
              isActive: _respondController.currentStep.value >= 0,
            ),
            Step(
              title: _stepTitle(context, 'Additional Info', 1),
              content: SecondStepContent(
                key: secondStepKey,
                validateForm: _respondController.registerFormFieldValidation,
                // formKey: formKey,
                respondController: _respondController,
                event: widget.event,
              ),
              isActive: _respondController.currentStep.value >= 1,
            ),
            Step(
              title: _stepTitle(context, 'Review & Submit', 2),
              content: ThirdStepContent(respondController: _respondController),
              isActive: _respondController.currentStep.value >= 2,
            ),
          ],
        );
      });
    }
  }

  /// Returns the step title widget, adapting its display based on screen size and current step.
  Widget _stepTitle(BuildContext context, String text, int stepNumber) {
    return ScreenSize.isPhone(context)
        ? (_respondController.currentStep.value == stepNumber
            ? AppText.styledBodyMedium(context, text)
            : SizedBox.shrink())
        : AppText.styledBodyMedium(context, text);
  }
}
