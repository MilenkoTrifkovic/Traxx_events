import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/menus_list_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/enums/sort_type.dart';

import 'package:google_fonts/google_fonts.dart';

class SortMenus extends StatelessWidget {
  const SortMenus({super.key});

  @override
  Widget build(BuildContext context) {
    final MenusListController controller = Get.find<MenusListController>();

    return PopupMenuButton<SortType>(
      onSelected: controller.sortMenus,
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<SortType>(
          value: SortType.dateNewest,
          child: Row(
            children: [
              const Icon(Icons.schedule, size: 18),
              const SizedBox(width: 8),
              Text(
                'Newest first',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem<SortType>(
          value: SortType.dateOldest,
          child: Row(
            children: [
              const Icon(Icons.schedule_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                'Oldest first',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<SortType>(
          value: SortType.nameAZ,
          child: Row(
            children: [
              const Icon(Icons.sort_by_alpha, size: 18),
              const SizedBox(width: 8),
              Text(
                'Name A → Z',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
        ),
        PopupMenuItem<SortType>(
          value: SortType.nameZA,
          child: Row(
            children: [
              const Icon(Icons.sort_by_alpha_outlined, size: 18),
              const SizedBox(width: 8),
              Text(
                'Name Z → A',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: AppPadding.horizontal(context, paddingType: Sizes.xxxs),
        child: SizedBox(
          height: 24,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort,
                size: 20,
                color: AppColors.primaryAccent,
              ),
              AppSpacing.horizontalXxxs(context),
              Text(
                'SORT BY',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
