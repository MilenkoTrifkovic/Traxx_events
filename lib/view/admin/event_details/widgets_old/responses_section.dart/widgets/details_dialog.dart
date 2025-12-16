import 'package:flutter/material.dart';
import 'package:traxx_wepapp/controller/admin_controllers/responses_controller.dart';
import 'package:traxx_wepapp/extensions/string_extensions.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/models/guest_response.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';
import 'package:intl/intl.dart';

class DetailsDialog extends StatelessWidget {
  const DetailsDialog(
      {super.key,
      required this.guestResponse,
      required this.responsesController});

  final GuestResponse guestResponse;
  final ResponsesController responsesController;

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        border:
            Border.all(color: AppColors.onBackground(context).withOpacity(0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: AppPadding.all(context, paddingType: Sizes.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).primaryColor),
              AppSpacing.horizontalXs(context),
              AppText.styledBodyLarge(context, title, weight: FontWeight.bold)
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value,
      {Color? textColor}) {
    return Padding(
      padding: AppPadding.bottom(context, paddingType: Sizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 2,
              child:
                  AppText.styledBodyMedium(context, label, isSelectable: true)),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: AppText.styledBodyMedium(context, value,
                color: textColor, isSelectable: true),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      header: Padding(
        padding: AppPadding.all(context, paddingType: Sizes.sm),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: AppColors.primaryOld(context),
                  ),
                  AppSpacing.horizontalXs(context),
                  Expanded(
                    child: AppText.styledHeadingSmall(
                      context,
                      family: Constants.font2,
                      weight: FontWeight.bold,
                      guestResponse.guestName ??
                          responsesController.guestName(guestResponse.guestId!),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                    onPressed: () => popRoute(context),
                    icon:
                        Icon(Icons.close, color: AppColors.onSurface(context))),
              ],
            )
          ],
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information Section
            _buildSection(
              context,
              'Basic Information',
              Icons.info_outline,
              children: [
                _buildInfoRow(
                    context,
                    'Guest Name',
                    guestResponse.guestName ??
                        responsesController.guestName(guestResponse.guestId!)),
                _buildInfoRow(
                    context,
                    guestResponse.inviterId != null ? 'Invited By' : 'Email',
                    guestResponse.inviterId != null
                        ? ('${responsesController.guestName(guestResponse.inviterId!)} (${responsesController.guestEmail(guestResponse.inviterId!)})')
                        : responsesController
                            .guestEmail(guestResponse.guestId!)),
                _buildInfoRow(
                  context,
                  'RSVP Status',
                  guestResponse.isAttending ? 'Attending' : 'Not Attending',
                  textColor:
                      guestResponse.isAttending ? Colors.green : Colors.red,
                ),
                if (guestResponse.createdAt != null)
                  _buildInfoRow(
                    context,
                    'Response Date',
                    DateFormat('MMM dd, yyyy HH:mm')
                        .format(guestResponse.createdAt!),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Menu Selections Section
            if (guestResponse.menus.isNotEmpty) ...[
              _buildSection(
                context,
                'Menu Selections',
                Icons.restaurant_menu,
                children: guestResponse.menus.entries.map((entry) {
                  return _buildInfoRow(
                    context,
                    entry.key.capitalizeString(),
                    responsesController.menuName(entry.value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Questions and Answers Section
            if (guestResponse.questionAnswers.isNotEmpty) ...[
              _buildSection(
                context,
                'Questions & Answers',
                Icons.question_answer,
                children: guestResponse.questionAnswers.map((question) {
                  return _buildInfoRow(
                    context,
                    question.fieldName!.capitalizeString(),
                    question.answer!.capitalizeString(),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      footer: null,
      // footer: Row(
      //   mainAxisAlignment: MainAxisAlignment.end,
      //   children: [
      //     StyledTextButton(onPressed: () => popRoute(context), text: 'Close'),
      //   ],
      // ),
    );
  }
}
