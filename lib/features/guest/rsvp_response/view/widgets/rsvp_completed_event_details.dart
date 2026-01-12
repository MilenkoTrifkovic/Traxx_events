import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/controller/rsvp_response_controller.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_form_widgets.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_loading_widget.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/layout/guest_layout/controllers/guest_layout_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:url_launcher/url_launcher.dart';

class RsvpCompletedEventDetailsWidget extends StatelessWidget {
  final bool isPhone;
  final RsvpResponseController controller;
  final GuestLayoutController guestController;

  const RsvpCompletedEventDetailsWidget({
    super.key,
    required this.isPhone,
    required this.controller,
    required this.guestController,
  });

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final event = guestController.event.value;

      if (event == null) {
        return RsvpLoadingWidget(isPhone: isPhone);
      }

      final coverUrl =
          (event.coverImageDownloadUrl ?? event.coverImageUrl ?? '').trim();

      final invitationLetterUrl = (event.invitationLetterUrl ?? '').trim();
      final guestPortalUrl = 'https://trax-event.app/guest-login';

      final venuePhotos = guestController.venuePhotoUrls.toList();

      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RsvpHeaderWidget(
              isPhone: isPhone,
              eventName: event.name,
              eventDate: event.date,
              startTime: event.startTime,
              endTime: event.endTime,
              eventAddress: event.address,
              eventType: event.eventType,
            ),

            SizedBox(height: AppSpacing.lg(context)),

            if (coverUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 6,
                  child: Image.network(
                    coverUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.surfaceCard,
                      alignment: Alignment.center,
                      child: Icon(Icons.image_not_supported_outlined,
                          color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),

            SizedBox(height: AppSpacing.lg(context)),

            // ✅ Venue photos
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.styledHeadingSmall(
                    context,
                    "Venue Photos",
                    weight: AppFontWeight.semiBold,
                  ),
                  SizedBox(height: AppSpacing.xs(context)),
                  if (guestController.isLoadingVenuePhotos.value)
                    Padding(
                      padding: EdgeInsets.only(top: AppSpacing.sm(context)),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: AppSpacing.sm(context)),
                          AppText.styledBodySmall(
                            context,
                            "Loading venue photos...",
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    )
                  else if (venuePhotos.isEmpty)
                    AppText.styledBodySmall(
                      context,
                      "No venue photos uploaded.",
                      color: AppColors.textMuted,
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.only(top: AppSpacing.sm(context)),
                      itemCount: venuePhotos.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isPhone ? 2 : 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 16 / 10,
                      ),
                      itemBuilder: (_, i) {
                        final url = venuePhotos[i];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surfaceCard,
                              alignment: Alignment.center,
                              child: Icon(Icons.broken_image_outlined,
                                  color: AppColors.textMuted),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.md(context)),

            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.styledHeadingSmall(
                    context,
                    "You're all set ✅",
                    weight: AppFontWeight.bold,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: AppSpacing.xs(context)),
                  AppText.styledBodyMedium(
                    context,
                    "You’ve already completed RSVP, demographic questions, and menu selection for this invitation.\n\n"
                    "If you want to change demographics or menu selection, please use the Guest Portal.",
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.md(context)),

            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.styledHeadingSmall(
                    context,
                    "Guest Portal",
                    weight: AppFontWeight.semiBold,
                  ),
                  SizedBox(height: AppSpacing.xs(context)),
                  AppText.styledBodySmall(
                    context,
                    "Log in to view and update your details anytime.",
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: AppSpacing.md(context)),
                  SizedBox(
                    width: double.infinity,
                    height: isPhone ? 52 : 56,
                    child: ElevatedButton.icon(
                      onPressed: () => _openUrl(guestPortalUrl),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text("Open Guest Portal"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.md(context)),

            // ✅ Invitation card ALWAYS shown (download or “not uploaded”)
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.styledHeadingSmall(
                    context,
                    "Invitation",
                    weight: AppFontWeight.semiBold,
                  ),
                  SizedBox(height: AppSpacing.xs(context)),
                  AppText.styledBodySmall(
                    context,
                    invitationLetterUrl.isNotEmpty
                        ? "Download your invitation file."
                        : "No invitation has been uploaded yet.",
                    color: AppColors.textMuted,
                  ),
                  SizedBox(height: AppSpacing.md(context)),
                  SizedBox(
                    width: double.infinity,
                    height: isPhone ? 52 : 56,
                    child: OutlinedButton.icon(
                      onPressed: invitationLetterUrl.isNotEmpty
                          ? () => _openUrl(invitationLetterUrl)
                          : null,
                      icon: const Icon(Icons.download_outlined),
                      label: Text(invitationLetterUrl.isNotEmpty
                          ? "Download Invitation"
                          : "No invitation available"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.borderSubtle),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.md(context)),

            Obx(() {
              final code = controller.invitationCode.value;
              final batch = controller.batchId.value;

              final items = <KeyValueItem>[
                if (code != null && code.isNotEmpty)
                  KeyValueItem("Invite Code", code),
                if (batch != null && batch.isNotEmpty)
                  KeyValueItem("Batch ID", batch),
                KeyValueItem("Invitation ID", controller.invitationId ?? ""),
              ];

              return _KeyValueCard(
                isPhone: isPhone,
                title: "Reference Information",
                items: items,
              );
            }),

            SizedBox(height: AppSpacing.xl(context)),
          ],
        ),
      );
    });
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ScreenSize.isPhone(context) ? 18 : 22),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _KeyValueCard extends StatelessWidget {
  final bool isPhone;
  final String title;
  final List<KeyValueItem> items;

  const _KeyValueCard({
    required this.isPhone,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 18 : 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.styledHeadingSmall(context, title,
              weight: AppFontWeight.semiBold),
          SizedBox(height: AppSpacing.sm(context)),
          ...items.map((kv) {
            final k = kv.keyText;
            final v = kv.valueText;

            return Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xs(context)),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: AppText.styledBodySmall(
                      context,
                      k,
                      color: AppColors.textMuted,
                      weight: AppFontWeight.medium,
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: AppText.styledBodySmall(
                      context,
                      v.isEmpty ? '—' : v,
                      color: AppColors.primary,
                      weight: AppFontWeight.semiBold,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

class KeyValueItem {
  final String keyText;
  final String valueText;
  const KeyValueItem(this.keyText, this.valueText);
}
