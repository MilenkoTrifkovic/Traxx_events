import 'package:flutter/material.dart';
import 'package:traxx_wepapp/controller/guest_controller.dart/guest_controller.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/guest_response.dart';
import 'package:traxx_wepapp/models/menu_old.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/styled_buttons/styled_text_button.dart';
import 'package:traxx_wepapp/view/guest/widgets/responses_table.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';

/// Displays a table of guest responses in a modal dialog.
/// Uses [GuestResponseTable] extension to format and display response data
/// in a consistent, themed layout.
class GuestResponsesModal extends StatelessWidget {
  final GuestController guestController;
  final List<GuestResponse> responses;
  final List<MenuItemOld> menuItems;

  const GuestResponsesModal({
    required this.guestController,
    required this.responses,
    required this.menuItems,
    super.key,
  });

  /// Shows the guest responses modal dialog.
  ///
  /// This static method provides a convenient way to display the modal dialog
  /// without directly instantiating the widget. It handles the dialog presentation
  /// and ensures proper context management.
  ///
  /// Parameters:
  /// - [context]: The BuildContext for showing the dialog
  /// - [guestController]: Controller managing guest state and operations
  /// - [responses]: List of responses to display
  /// - [menuItems]: Available menu items for resolving selections
  ///
  /// Returns a Future that completes when the dialog is dismissed.
  static Future<void> show(
    BuildContext context, {
    required GuestController guestController,
    required List<GuestResponse> responses,
    required List<MenuItemOld> menuItems,
  }) {
    return showDialog(
      context: context,
      builder: (_) => GuestResponsesModal(
        guestController: guestController,
        responses: responses,
        menuItems: menuItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
        header: _buildHeader(context),
        content: ResponsesTable(
            responses: guestController.getAllResponsesAsTableRows()),
        //After RSVP deadline new response can't be submitted
        footer:
            guestController.rsvpDeadlineValid() ? _buildFooter(context) : null);
  }

  /// Builds the header section of the modal.
  ///
  /// Creates a styled header with title and close button using the app's
  /// design system. Uses [AppColors] and [AppPadding] for consistent styling.
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: AppPadding.all(context, paddingType: Sizes.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer(context).withAlpha(64),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.mobileValues[Sizes.md]!),
          topRight: Radius.circular(AppBorderRadius.mobileValues[Sizes.md]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: AppText.styledHeadingSmall(
              family: Constants.font2,
              weight: FontWeight.bold,
              context,
              'Guest Responses',
              color: AppColors.onSurface(context),
            ),
          ),
          IconButton(
            onPressed: () => popRoute(context),
            icon: Icon(
              Icons.close,
              color: AppColors.onSurface(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the footer section of the modal.
  ///
  /// Creates a styled footer with submit button
  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: AppPadding.all(context, paddingType: Sizes.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer(context).withAlpha(32),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(AppBorderRadius.mobileValues[Sizes.md]!),
          bottomRight: Radius.circular(AppBorderRadius.mobileValues[Sizes.md]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          StyledTextButton(
              onPressed: () {
                popRoute(context);
                pushAndRemoveAllRoute(AppRoute.guestEventRespond, context,
                    urlParam: guestController.selectedEvent.value.eventId);
              },
              text: 'Submit new response'),
        ],
      ),
    );
  }
}
