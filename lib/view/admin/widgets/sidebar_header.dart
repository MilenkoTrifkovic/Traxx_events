import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// Sidebar header with toggle button and logo/organisation name.
class SidebarHeader extends StatelessWidget {
  final bool isExpanded;
  final bool actuallyCollapsed;
  final String organisationName;
  final String? organisationPhotoUrl;
  final VoidCallback onToggleExpand;

  const SidebarHeader({
    super.key,
    required this.isExpanded,
    required this.actuallyCollapsed,
    required this.organisationName,
    this.organisationPhotoUrl,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toggle button
        Padding(
          padding: EdgeInsets.fromLTRB(
            isExpanded ? 18 : 16,
            12,
            isExpanded ? 18 : 16,
            8,
          ),
          child: Align(
            alignment: isExpanded ? Alignment.centerRight : Alignment.center,
            child: IconButton(
              onPressed: onToggleExpand,
              icon: Icon(
                isExpanded ? Icons.chevron_left : Icons.chevron_right,
                color: AppColors.white,
              ),
              tooltip: isExpanded ? 'Collapse sidebar' : 'Expand sidebar',
              iconSize: 24,
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),

        // Logo and organisation name
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: actuallyCollapsed ? 0 : 18,
            ),
            child: Row(
              mainAxisAlignment: actuallyCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                // Logo container
                Container(
                  width: actuallyCollapsed ? 36 : 40,
                  height: actuallyCollapsed ? 36 : 40,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: organisationPhotoUrl != null
                        ? Image.network(
                            organisationPhotoUrl!,
                            width: actuallyCollapsed ? 36 : 40,
                            height: actuallyCollapsed ? 36 : 40,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: Icon(
                                  Icons.auto_awesome,
                                  color: AppColors.primary,
                                  size: actuallyCollapsed ? 20 : 24,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.auto_awesome,
                                color: AppColors.primary,
                                size: actuallyCollapsed ? 20 : 24,
                              );
                            },
                          )
                        : Icon(
                            Icons.auto_awesome,
                            color: AppColors.primary,
                            size: actuallyCollapsed ? 20 : 24,
                          ),
                  ),
                ),

                // Organisation name - animated fade
                if (!actuallyCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      organisationName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(
            color: AppColors.white.withOpacity(0.15),
            thickness: 1,
            height: 1,
          ),
        ),
      ],
    );
  }
}
