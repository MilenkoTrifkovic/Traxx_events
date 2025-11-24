import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_workers/rx_workers.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/enums/snack_bar_type.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/view/common/event_list_screen.dart';

class ContentWrapper extends StatefulWidget {
  final Widget child;
  final Widget? header;
  final double maxWidth;
  final Alignment alignment;
  final Color? contentColor;
  final BoxShadow? shadow;

  const ContentWrapper({
    super.key,
    required this.child,
    this.header,
    this.maxWidth = Constants.maxContentWidth,
    this.alignment = Alignment.center,
    this.contentColor,
    this.shadow,
  });

  @override
  State<ContentWrapper> createState() => _ContentWrapperState();
}

class _ContentWrapperState extends State<ContentWrapper> {
  SnackbarMessageController controller = Get.put(SnackbarMessageController());
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ever(controller.message, (message) {
      if (message != null && context.mounted) {
        if (message.type == SnackBarType.success) {
          SnackBarUtils.showSuccess(context, message.message);
        } else {
          SnackBarUtils.showError(context, message.message);
        }

        // Clear message after showing
        controller.clearMessage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double effectiveMaxWidth =
              constraints.maxWidth > widget.maxWidth
                  ? widget.maxWidth
                  : constraints.maxWidth;

          return Container(
            alignment: widget.alignment,
            child: Container(
              constraints: BoxConstraints(
                  // maxWidth: effectiveMaxWidth,
                  ),
              decoration: BoxDecoration(
                // color: contentColor ?? AppColors.surface(context),
                // color: AppColors.fofofo,
                // boxShadow: [
                //   shadow ??
                //       BoxShadow(
                //         color: AppColors.shadow(context).withAlpha(50),
                //         blurRadius: 6,
                //         offset: const Offset(0, 2),
                //       ),
                // ],
                color: widget.contentColor ?? AppColors.fofofo,
                boxShadow: widget.shadow != null ? [widget.shadow!] : null,
              ),
              child: widget.header != null
                  ? Column(
                      children: [
                        Padding(
                          padding: AppPadding.bottom(context,
                              paddingType: Sizes.xxs),
                          child: widget.header!,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: ConstrainedBox(
                                constraints:
                                    BoxConstraints(maxWidth: effectiveMaxWidth),
                                child: widget.child,
                              ),
                            ),
                          ),
                        )
                      ],
                    )
                  : widget.child,
            ),
          );
        },
      ),
    );
  }
}
