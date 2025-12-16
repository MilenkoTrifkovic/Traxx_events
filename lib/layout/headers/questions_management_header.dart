import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

class QuestionsManagementHeader extends StatelessWidget {
  QuestionsManagementHeader({super.key});
  final EventListController eventListController =
      Get.find<EventListController>();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText.styledHeadingLarge(context, 'Demographic Questions'),
        /*  Row(
          children: [
            AppPrimaryButton(
              icon: Icons.add,
              text: 'Add Question',
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const AddQuestionDialog(
                    questionSetId: '',
                  ),
                );
              },
            ),
          ],
        ) */
      ],
    );
  }
}
