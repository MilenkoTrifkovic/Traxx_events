import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/controllers/guest_demographics_edit_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_responses_preview_edit/widgets/demographic_question_widget.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';

/// Page for editing demographic responses
class GuestDemographicsEditPage extends StatefulWidget {
  const GuestDemographicsEditPage({super.key});

  @override
  State<GuestDemographicsEditPage> createState() => _GuestDemographicsEditPageState();
}

class _GuestDemographicsEditPageState extends State<GuestDemographicsEditPage> {
  late final GuestDemographicsEditController controller;
  late final SnackbarMessageController snackbarController;

  @override
  void initState() {
    super.initState();
    controller = Get.put(GuestDemographicsEditController());
    snackbarController = Get.find<SnackbarMessageController>();

    // Get guestId from navigation extra and initialize controller ONCE
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final guestId = extra?['guestId'] as String?;
      controller.initialize(guestId: guestId);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Edit Demographics'),
        backgroundColor: AppColors.primaryAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => controller.cancel(context),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.demographicQuestions.isEmpty) {
          return const Center(
            child: Text('No demographic questions found'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Please answer the following questions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fields marked with * are required',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Questions list
                  ...controller.demographicQuestions.map((question) {
                    return Obx(() => DemographicQuestionWidget(
                          question: question,
                          currentAnswer:
                              controller.formAnswers[question.questionId],
                          onAnswerChanged: (answer) {
                            controller.updateAnswer(question.questionId, answer);
                          },
                        ));
                  }).toList(),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: controller.isSaving.value
                              ? null
                              : () => controller.cancel(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: AppPrimaryButton(
                          text: controller.isSaving.value
                              ? 'Saving...'
                              : 'Save Changes',
                          onPressed: controller.isSaving.value
                              ? () {}
                              : () async {
                                  final success =
                                      await controller.saveResponses();
                                  if (context.mounted) {
                                    if (success) {
                                      snackbarController.showSuccessMessage(
                                          'Demographics saved successfully');
                                      Navigator.of(context).pop();
                                    } else {
                                      snackbarController.showErrorMessage(
                                          'Please answer all required questions');
                                    }
                                  }
                                },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
