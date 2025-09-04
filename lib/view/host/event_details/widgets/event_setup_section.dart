import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/styled_buttons/styled_text_button.dart';
import 'package:traxx_wepapp/widgets/dialogs/dialogs.dart';

class EventSetupSection extends StatelessWidget {
  const EventSetupSection({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxWidth = constraints.maxWidth;
        final int columns = maxWidth >= 1000 ? 3 : (maxWidth >= 600 ? 2 : 1);
        final double spacing = AppSpacing.sm(context);
        final double itemWidth = (maxWidth - (columns - 1) * spacing) / columns;
        List<Widget> widgets = [
          _buildWidgetItem(
            context,
            itemWidth,
            Icons.menu,
            'Menus',
            '',
            () {
              pushRoute(AppRoute.eventMenus, context);
            },
          ),
          _buildWidgetItem(
              context, itemWidth, Icons.question_mark, 'Questions', '', () {
            pushRoute(AppRoute.eventQuestions, context);
          }),
          _buildWidgetItem(context, itemWidth, Icons.people, 'Guests', '', () {
            pushRoute(AppRoute.eventGuests, context);
          }),
          _buildWidgetItem(context, itemWidth, Icons.question_answer,
              'Responses', 'Answered: 5t')
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Wrap(
              alignment: WrapAlignment.start,
              spacing: spacing,
              children: widgets,
            ),
            StyledTextButton(
                onPressed: () {
                  Dialogs.showConfirmationDialog(
                      context,
                      "After Finalizing, Menus and Questions will be locked for editing.",
                      () {});
                },
                text: 'Finalize Menus and Questions')
          ],
        );
      },
    );
  }

  Widget _buildWidgetItem(BuildContext context, double width, IconData icon,
      String label, String value,
      [VoidCallback? onPressed]) {
    return Padding(
      padding: AppPadding.vertical(context, paddingType: Sizes.sm),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 4,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: width,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icon, size: 60),
                AppSpacing.horizontalXs(context),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.styledBodyLarge(context, label,
                        weight: FontWeight.bold,
                        color: AppColors.onBackground(context)),
                    const SizedBox(height: 4),
                    AppText.styledBodyMedium(context, value),
                  ],
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
