import 'package:flutter/material.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/widgets/first_section_guest.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/widgets/fourth_section_guest.dart';
import 'package:traxx_wepapp/features/admin/admin_guests_management/widgets/second_section_guest.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// A card widget that displays event information in a consistent format.
///
/// Features:
/// - Displays event cover image with fallback placeholder
/// - Shows event name, date, and status
class GuestCard extends StatelessWidget {
  /// The event data to display in the card
  final GuestModel guest;

  /// Callback function when the card is tapped
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const GuestCard({
    super.key,
    required this.guest,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(
          color: AppColors.borderInput,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow(context).withAlpha(50),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        borderRadius: BorderRadius.circular(8),
      ),
      height: 50,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Expanded(child: FirstSectionGuest(guest: guest, onPressed: (){})),
            if (ScreenSize.isDesktop(context))
              Expanded(child: SecondSectionGuest(guest: guest, onPressed: (){})),
            // if (ScreenSize.isDesktop(context))
            //   Expanded(child: ThirdSection(event: event)),
            // if (ScreenSize.isDesktop(context))
              Expanded(child: FourthSectionGuest(guest: guest, onPressed: onDelete, onEdit: onEdit)),
          ],
        ),
      ),
    );
    // return Card(
    //   clipBehavior: Clip.antiAlias,
    //   elevation: 2,
    //   child: InkWell(
    //     onTap: onTap,
    //     child: Padding(
    //       padding: AppPadding.all(context, paddingType: Sizes.sm),
    //       child: Row(
    //         children: [
    //           Expanded(child: FirstSection(event: event)),
    //           Expanded(child: SecondSection(event: event)),
    //           Expanded(child: ThirdSection(event: event)),
    //           Expanded(child: FourthSection(event: event)),
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
}
