import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/constants.dart';

/// Sidebar footer with app name and version.
class SidebarFooter extends StatelessWidget {
  final bool isExpanded;
  final bool actuallyCollapsed;

  const SidebarFooter({
    super.key,
    required this.isExpanded,
    required this.actuallyCollapsed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        actuallyCollapsed ? 12 : 18,
        12,
        actuallyCollapsed ? 12 : 18,
        16,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: actuallyCollapsed
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // App name
          if (!actuallyCollapsed) ...[
            Text(
              Constants.appName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
          ],
          
          // Version badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: actuallyCollapsed ? 6 : 8,
              vertical: actuallyCollapsed ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'v${Constants.traxVersion}',
              style: GoogleFonts.poppins(
                fontSize: actuallyCollapsed ? 9 : 11,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }
}
