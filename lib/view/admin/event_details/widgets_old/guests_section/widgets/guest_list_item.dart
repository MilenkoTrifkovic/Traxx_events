import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/guests_controllers/set_guests_controller.dart';
import 'package:traxx_wepapp/helper/app_decoration.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/models/guest_dart.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/extensions/string_extensions.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/utils/styled_buttons/styled_text_button.dart';
import 'package:traxx_wepapp/widgets/dialogs/dialogs.dart';

/// A single guest item widget for use within an [AnimatedList].
///
/// Displays guest information (email, name, companions) in a row format with a delete button and invite button.
/// Supports smooth animation for insertion and removal from the list.
/// supports tween animations for added item
class GuestListItem extends StatefulWidget {
  final Guest_old item;
  final Animation<double> animation;
  final void Function(int index) onPressed;
  final int index;
  final Color? color;

  const GuestListItem(
      {super.key,
      required this.item,
      required this.animation,
      required this.onPressed,
      required this.index,
      this.color});

  @override
  State<GuestListItem> createState() => _GuestListItemState();
}

class _GuestListItemState extends State<GuestListItem> {
  final SetGuestsController setGuestsController =
      Get.find<SetGuestsController>();
  late final SnackbarMessageController snackbarController;

  @override
  void initState() {
    super.initState();
    snackbarController = Get.find<SnackbarMessageController>();
  }

  String? fieldValidation(String message, String? value) {
    if (value == null || value.isEmpty) {
      return message;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(
        parent: widget.animation,
        curve: Curves.easeOut,
      ),
      axisAlignment: 0.0,
      child: TweenAnimationBuilder(
        duration: Duration(seconds: 3),
        tween: ColorTween(
            begin: widget.color ??
                AppColors.primaryContainer(context).withAlpha(64),
            end: AppColors.primaryContainer(context).withAlpha(64)),
        builder: (context, color, child) {
          return Container(
            height: Constants.guestListContainerHeight,
            decoration: AppDecorations.listDecoration(context, color: color),
            child: child,
          );
        },
        child: Row(
          children: [
            // Email
            Expanded(
              flex: 5,
              child: Padding(
                padding: AppPadding.horizontal(context, paddingType: Sizes.xs),
                child: AppText.styledBodyMedium(
                  context,
                  widget.item.email,
                  overflow: TextOverflow.ellipsis,
                  isSelectable: true,
                ),
              ),
            ),
            // Name
            Expanded(
              flex: 5,
              child: Padding(
                padding: AppPadding.horizontal(context, paddingType: Sizes.xs),
                child: AppText.styledBodyMedium(
                    context, widget.item.name.capitalizeString(),
                    overflow: TextOverflow.ellipsis, isSelectable: true),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: AppPadding.horizontal(context, paddingType: Sizes.xs),
                // Companions, delete, invite
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Companions
                    AppText.styledBodyMedium(
                      context,
                      '${widget.item.companions}',
                      isSelectable: true,
                    ),
                    Row(
                      children: [
                        //invite
                        StyledTextButton(
                          onPressed: widget.item.invited
                              ? null
                              : () async {
                                  try {
                                    await setGuestsController
                                        .inviteGuest(widget.item);
                                    setState(() {});
                                  } catch (e) {
                                    snackbarController.showErrorMessage(
                                        'Invitation failed');
                                  }
                                },
                          text: widget.item.invited ? 'Invited' : 'Invite',
                        ),
                        //delete
                        IconButton(
                          icon: Icon(Icons.delete,
                              color: AppColors.error(context), size: 20),
                          // onPressed: () => widget.onPressed(widget.index),
                          onPressed: () {
                            Dialogs.showConfirmationDialog(context,
                                'Are you sure you want to delete ${widget.item.name.capitalize}?',
                                () {
                              widget.onPressed(widget.index);
                            });
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
