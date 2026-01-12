import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/layout/guest_layout/controllers/guest_layout_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

class GuestPageWrapper extends StatefulWidget {
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
  State<GuestPageWrapper> createState() => _GuestPageWrapperState();
}

class _GuestPageWrapperState extends State<GuestPageWrapper> {
  GuestLayoutController? _controller;

  GuestLayoutController _ensureController() {
    final id = widget.invitationId;

    // ✅ IMPORTANT: use tag = invitationId
    if (Get.isRegistered<GuestLayoutController>(tag: id)) {
      return Get.find<GuestLayoutController>(tag: id);
    }
    return Get.put(GuestLayoutController(), tag: id);
  }

  void _loadForCurrentInvitation() {
    final c = _controller;
    if (c == null) return;

    // ✅ Let GuestLayoutController handle its own caching/guard logic
    c.loadEventCoverImageFromInvitation(widget.invitationId);
  }

  @override
  void initState() {
    super.initState();
    _controller = _ensureController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForCurrentInvitation();
    });
  }

  @override
  void didUpdateWidget(covariant GuestPageWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If invitationId changes, switch to correct tagged controller + load
    if (oldWidget.invitationId != widget.invitationId) {
      _controller = _ensureController();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadForCurrentInvitation();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller ?? _ensureController();

    final isPhone = ScreenSize.isPhone(context);
    final isTablet = ScreenSize.isTablet(context);

    return Scaffold(
      backgroundColor: widget.backgroundColor ?? AppColors.surfaceCard,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Cover image
            Obx(() {
              final imageUrl = controller.eventCoverImageUrl.value;
              final loading = controller.isLoadingImage.value;

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
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _fallbackImage(loading),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _loadingImage(loadingProgress);
                        },
                      )
                    : _fallbackImage(loading),
              );
            }),

            // Content
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 1024),
              padding: EdgeInsets.symmetric(
                horizontal:
                    isPhone ? AppSpacing.lg(context) : AppSpacing.xl(context),
                vertical: isPhone
                    ? AppSpacing.xxxl(context)
                    : AppSpacing.xxxxl(context),
              ),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackImage(bool loading) {
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
        child: loading
            ? CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryAccent,
              )
            : Icon(
                Icons.image_outlined,
                size: 64,
                color: AppColors.textMuted,
              ),
      ),
    );
  }

  Widget _loadingImage(ImageChunkEvent loadingProgress) {
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
  }
}
