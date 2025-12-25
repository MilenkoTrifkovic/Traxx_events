import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/layout/guest_layout/controllers/guest_layout_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// Wrapper widget for all guest-facing pages (RSVP, demographics, menu, thank you)
/// Professional layout: hero cover image on top, content below with proper spacing
class GuestPageWrapper extends StatelessWidget {
  /// The child widget to display below the image
  final Widget child;
  
  /// Invitation ID to fetch event cover image
  final String invitationId;

  /// Optional background color (defaults to surfaceCard)
  final Color? backgroundColor;

  const GuestPageWrapper({
    super.key,
    required this.child,
    required this.invitationId,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Get or create controller and load image
    final controller = Get.put(GuestLayoutController());
    
    // Load event cover image from invitation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadEventCoverImageFromInvitation(invitationId);
    });

    final isPhone = ScreenSize.isPhone(context);
    final isTablet = ScreenSize.isTablet(context);

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.surfaceCard,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero cover image section with elegant aspect ratio
            // Obx watches controller.eventCoverImageUrl for reactive updates
            Obx(() {
              final imageUrl = controller.eventCoverImageUrl.value;
              
              return Container(
                width: double.infinity,
                height: isPhone ? 200 : (isTablet ? 280 : 320),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.skeletonBase,
                                  AppColors.skeletonHighlight,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 64,
                                color: AppColors.textMuted,
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.skeletonBase,
                                  AppColors.skeletonHighlight,
                                ],
                              ),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                strokeWidth: 2,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.skeletonBase,
                              AppColors.skeletonHighlight,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 64,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
              );
            }),

            // Content section with professional spacing using AppSpacing
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 1024),
              padding: EdgeInsets.symmetric(
                horizontal: isPhone 
                    ? AppSpacing.lg(context) 
                    : AppSpacing.xl(context),
                vertical: isPhone 
                    ? AppSpacing.xxxl(context) 
                    : AppSpacing.xxxxl(context),
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}
