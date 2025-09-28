import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/guest_controller.dart/respond_controller.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

class ThirdStepContent extends StatefulWidget {
  final RespondController respondController;
  const ThirdStepContent({super.key, required this.respondController});

  @override
  State<ThirdStepContent> createState() => _ThirdStepContentState();
}

class _ThirdStepContentState extends State<ThirdStepContent> {
  final scrollController = ScrollController();
  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: AppBorderRadius.radius(context, size: Sizes.sm),
            side: BorderSide(
              color: AppColors.primary(context).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: AppPadding.all(context, paddingType: Sizes.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  final responses =
                      widget.respondController.getAllResponsesAsTableRows();

                  return Scrollbar(
                    controller: scrollController,
                    thumbVisibility: true,
                    interactive: true,
                    child: SingleChildScrollView(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width * 0.9,
                        ),
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                            AppColors.primary(context).withOpacity(0.1),
                          ),
                          dataRowColor:
                              WidgetStateProperty.resolveWith((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return AppColors.primary(context)
                                  .withOpacity(0.05);
                            }
                            return null;
                          }),
                          columnSpacing: 24,
                          horizontalMargin: 12,
                          columns: responses.first.keys
                              .map((e) => DataColumn(
                                    label: AppText.styledBodyMedium(
                                      context,
                                      e,
                                      weight: FontWeight.bold,
                                    ),
                                  ))
                              .toList(),
                          rows: responses
                              .map((e) => DataRow(
                                    cells: e.values
                                        .map((value) => DataCell(
                                              AppText.styledBodyMedium(
                                                  context, value),
                                            ))
                                        .toList(),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
