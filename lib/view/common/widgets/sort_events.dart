import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/event_list_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/enums/sort_type.dart';

/// A dropdown widget for sorting events with multiple options.
///
/// Provides sorting by:
/// - Date (newest/oldest)
/// - Name (A-Z/Z-A)
///
/// Uses HostController to manage sorting state and operations.
class SortEvents extends StatelessWidget {
  const SortEvents({super.key});

  @override
  Widget build(BuildContext context) {
    final EventListController controller = Get.find<EventListController>();

    return PopupMenuButton<SortType>(
      child: Padding(
        padding: AppPadding.horizontal(context, paddingType: Sizes.xxxs),
        child: SizedBox(
          height: 24,
          // padding: AppPadding.all(context, paddingType: Sizes.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort,
                size: 20,
                color: AppColors.primaryAccent,
              ),
              AppSpacing.horizontalXxxs(context),
              AppText.styledBodyMedium(
                context,
                'SORT BY',
              ),
            ],
          ),
        ),
      ),
      onSelected: (SortType sortType) {
        controller.sortEvents(sortType);
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<SortType>(
          value: SortType.dateNewest,
          child: Row(
            children: [
              Icon(Icons.arrow_upward, size: 20),
              AppSpacing.horizontalXs(context),
              Text('Newest First'),
            ],
          ),
        ),
        PopupMenuItem<SortType>(
          value: SortType.dateOldest,
          child: Row(
            children: [
              Icon(Icons.arrow_downward, size: 20),
              AppSpacing.horizontalXs(context),
              Text('Oldest First'),
            ],
          ),
        ),
        PopupMenuItem<SortType>(
          value: SortType.nameAZ,
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha, size: 20),
              AppSpacing.horizontalXs(context),
              Text('A to Z'),
            ],
          ),
        ),
        PopupMenuItem<SortType>(
          value: SortType.nameZA,
          child: Row(
            children: [
              Icon(Icons.sort_by_alpha_outlined, size: 20),
              AppSpacing.horizontalXs(context),
              Text('Z to A'),
            ],
          ),
        ),
      ],
    );
  }
}
