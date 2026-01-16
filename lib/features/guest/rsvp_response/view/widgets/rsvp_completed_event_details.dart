import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/utils/enums/event_type.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:traxx_wepapp/features/guest/rsvp_response/controller/rsvp_response_controller.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_form_widgets.dart';
import 'package:traxx_wepapp/features/guest/rsvp_response/view/widgets/rsvp_loading_widget.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/layout/guest_layout/controllers/guest_layout_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

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

  Future<void> _copy(BuildContext context, String label, String value) async {
    if (value.trim().isEmpty) return;
    await Clipboard.setData(ClipboardData(text: value.trim()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _prettyServiceType(ServiceType? v) {
    if (v == null) return '—';
    final raw = v.name.trim(); // e.g. "buffet" or "food_stations"
    if (raw.isEmpty) return '—';

    final cleaned = raw.replaceAll('_', ' ').replaceAll('-', ' ');
    return cleaned
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  // --- Typography (different font + bigger / trendier scale) ---
  TextStyle _h1(BuildContext context) => GoogleFonts.manrope(
        fontSize: isPhone ? 20 : 22,
        fontWeight: FontWeight.w800,
        height: 1.15,
        color: AppColors.black,
      );

  TextStyle _h2(BuildContext context) => GoogleFonts.manrope(
        fontSize: isPhone ? 18 : 20,
        fontWeight: FontWeight.w800,
        height: 1.15,
        color: AppColors.black,
      );

  TextStyle _muted(BuildContext context) => GoogleFonts.manrope(
        fontSize: isPhone ? 13 : 14,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: AppColors.textMuted,
      );

  TextStyle _body(BuildContext context) => GoogleFonts.manrope(
        fontSize: isPhone ? 14 : 15,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.black,
      );

  TextStyle _valueStrong(BuildContext context) => GoogleFonts.manrope(
        fontSize: isPhone ? 15 : 16,
        fontWeight: FontWeight.w800,
        height: 1.35,
        color: AppColors.primary,
      );

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final event = guestController.event.value;
      if (event == null) return RsvpLoadingWidget(isPhone: isPhone);

      final invitationLetterUrl = (event.invitationLetterUrl ?? '').trim();
      final guestPortalUrl = 'https://trax-event.app/guest-login';
      final venuePhotos = guestController.venuePhotoUrls.toList();

      // ✅ Make page use more width (big screens) but still look premium
      final screenW = MediaQuery.sizeOf(context).width;
      final maxWidth = math.min(screenW - (isPhone ? 24 : 72), 1320.0);

      final isWide = maxWidth >= 980;

      return DefaultTextStyle(
        style: GoogleFonts.manrope(
          fontSize: isPhone ? 14 : 15,
          height: 1.35,
          color: AppColors.black,
        ),
        child: Stack(
          children: [
            // ✅ Trendy soft background
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFF6F8FF),
                      Color(0xFFF7F7FA),
                      Color(0xFFFFFFFF),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              top: -120,
              right: -120,
              child: _BlurBlob(color: AppColors.primary.withOpacity(0.12)),
            ),
            Positioned(
              bottom: -140,
              left: -140,
              child: _BlurBlob(color: AppColors.primary.withOpacity(0.08)),
            ),

            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    isPhone ? 12 : 24,
                    isPhone ? 14 : 18,
                    isPhone ? 12 : 24,
                    isPhone ? 28 : 40,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Keep your existing header
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

                      // ✅ Success banner (more premium than a plain card)
                      _SuccessBanner(
                        isPhone: isPhone,
                        titleStyle: _h1(context),
                        mutedStyle: _muted(context),
                      ),

                      SizedBox(height: AppSpacing.md(context)),

                      // ✅ Action strip: Guest Portal + Invitation Download
                      _TrendCard(
                        padding: EdgeInsets.all(isPhone ? 16 : 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _IconBadge(
                                  icon: Icons.bolt_rounded,
                                  tint: AppColors.primary.withOpacity(0.12),
                                  iconColor: AppColors.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Quick actions',
                                    style: _h2(context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Access your portal anytime, or download the invitation file.',
                              style: _muted(context),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: isWide ? 260 : double.infinity,
                                  height: isPhone ? 50 : 54,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openUrl(guestPortalUrl),
                                    icon: const Icon(Icons.open_in_new_rounded),
                                    label: Text(
                                      'Open Guest Portal',
                                      style: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w800,
                                        fontSize: isPhone ? 14 : 15,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: AppColors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: isWide ? 260 : double.infinity,
                                  height: isPhone ? 50 : 54,
                                  child: OutlinedButton.icon(
                                    onPressed: invitationLetterUrl.isNotEmpty
                                        ? () => _openUrl(invitationLetterUrl)
                                        : null,
                                    icon: const Icon(
                                      Icons.download_rounded,
                                      color: Colors.white,
                                    ),
                                    label: Text(
                                      invitationLetterUrl.isNotEmpty
                                          ? 'Download Invitation'
                                          : 'No invitation uploaded',
                                      style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w800,
                                          fontSize: isPhone ? 14 : 15,
                                          color: Colors.white),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: BorderSide(
                                          color: AppColors.borderSubtle),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: AppSpacing.md(context)),

                      // ✅ Main content: trendy responsive layout
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                children: [
                                  _buildVenuePhotosCard(
                                      context, venuePhotos, isWide),
                                  SizedBox(height: AppSpacing.md(context)),
                                  _buildEventDetailsCard(context, event),
                                ],
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  _buildReferenceCard(context),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildVenuePhotosCard(context, venuePhotos, isWide),
                            SizedBox(height: AppSpacing.md(context)),
                            _buildEventDetailsCard(context, event),
                            SizedBox(height: AppSpacing.md(context)),
                            _buildReferenceCard(context),
                          ],
                        ),

                      SizedBox(height: AppSpacing.xl(context)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildVenuePhotosCard(
      BuildContext context, List<String> venuePhotos, bool isWide) {
    return _TrendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                icon: Icons.photo_library_rounded,
                tint: AppColors.primary.withOpacity(0.12),
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Venue photos',
                  style: _h2(context),
                ),
              ),
              if (venuePhotos.isNotEmpty)
                Text(
                  '${venuePhotos.length}',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (guestController.isLoadingVenuePhotos.value)
            Row(
              children: [
                const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text('Loading venue photos...', style: _muted(context)),
              ],
            )
          else if (venuePhotos.isEmpty)
            Text('No venue photos uploaded.', style: _muted(context))
          else
            SizedBox(
              height: isPhone ? 170 : 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: venuePhotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final url = venuePhotos[i];

                  return InkWell(
                    onTap: () => _openUrl(url),
                    borderRadius: BorderRadius.circular(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
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
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventDetailsCard(BuildContext context, dynamic event) {
    final dress = (event.dressCode ?? '').toString().trim();
    final notes = (event.specialNotes ?? '').toString().trim();
    final desc = (event.description ?? '').toString().trim();

    return _TrendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconBadge(
                icon: Icons.info_rounded,
                tint: AppColors.primary.withOpacity(0.12),
                iconColor: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Event details',
                  style: _h1(context), // ✅ bigger
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            label: 'Service Type',
            value: _prettyServiceType(event.serviceType),
            labelStyle: _muted(context),
            valueStyle: _valueStrong(context),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Dress Code',
            value: dress.isEmpty ? '—' : dress,
            labelStyle: _muted(context),
            valueStyle: _valueStrong(context),
          ),
          const SizedBox(height: 16),
          _BlockField(
            title: 'Special Notes',
            value: notes.isEmpty ? '—' : notes,
            titleStyle: _muted(context),
            valueStyle: _body(context).copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: isPhone ? 15 : 16,
            ),
          ),
          const SizedBox(height: 14),
          _BlockField(
            title: 'Description',
            value: desc.isEmpty ? '—' : desc,
            titleStyle: _muted(context),
            valueStyle: _body(context).copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
              fontSize: isPhone ? 15 : 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceCard(BuildContext context) {
    return Obx(() {
      final code = (controller.invitationCode.value ?? '').trim();
      final batch = (controller.batchId.value ?? '').trim();
      final invId = (controller.invitationId ?? '').trim();

      return _TrendCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _IconBadge(
                  icon: Icons.qr_code_2_rounded,
                  tint: AppColors.primary.withOpacity(0.12),
                  iconColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reference information',
                    style: _h1(context), // ✅ bigger
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Use these details for support or to reference your invitation.',
              style: _muted(context),
            ),
            const SizedBox(height: 14),
            if (code.isNotEmpty)
              _CopyRow(
                label: 'Invite Code',
                value: code,
                labelStyle: _muted(context),
                valueStyle: _valueStrong(context),
                onCopy: () => _copy(context, 'Invite Code', code),
              ),
            if (code.isNotEmpty) const SizedBox(height: 10),
            if (batch.isNotEmpty)
              _CopyRow(
                label: 'Batch ID',
                value: batch,
                labelStyle: _muted(context),
                valueStyle: _valueStrong(context),
                onCopy: () => _copy(context, 'Batch ID', batch),
              ),
            if (batch.isNotEmpty) const SizedBox(height: 10),
            _CopyRow(
              label: 'Invitation ID',
              value: invId.isEmpty ? '—' : invId,
              labelStyle: _muted(context),
              valueStyle:
                  _valueStrong(context).copyWith(fontSize: isPhone ? 14 : 15),
              onCopy: invId.isEmpty
                  ? null
                  : () => _copy(context, 'Invitation ID', invId),
            ),
          ],
        ),
      );
    });
  }
}

// =========================
// Trendy UI building blocks
// =========================

class _TrendCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const _TrendCard({
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final p = padding ?? EdgeInsets.all(ScreenSize.isPhone(context) ? 16 : 18);

    // subtle “glass” look + nicer radius
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFFBFCFF),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: p,
        child: child,
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color iconColor;

  const _IconBadge({
    required this.icon,
    required this.tint,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: iconColor, size: 22),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final bool isPhone;
  final TextStyle titleStyle;
  final TextStyle mutedStyle;

  const _SuccessBanner({
    required this.isPhone,
    required this.titleStyle,
    required this.mutedStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isPhone ? 16 : 18),
      decoration: BoxDecoration(
        color: AppColors.white, // ✅ old style background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFEAF7EE), // ✅ subtle success tint (optional)
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFE8C9)),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF1E8E3E), // ✅ success green
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "You're all set",
                  style: titleStyle.copyWith(
                    color: AppColors.black, // ✅ no tinted title
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "You’ve already completed RSVP, demographic questions, and menu selection for this invitation.",
                  style: mutedStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.trim().isEmpty ? '—' : value.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: labelStyle),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Text(v, style: valueStyle),
        ),
      ],
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final VoidCallback? onCopy;

  const _CopyRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.trim().isEmpty ? '—' : value.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 4,
          child: Text(label, style: labelStyle),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  v,
                  style: valueStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onCopy,
                tooltip: onCopy == null ? null : 'Copy',
                icon: Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color:
                      onCopy == null ? AppColors.textMuted : AppColors.primary,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BlockField extends StatelessWidget {
  final String title;
  final String value;
  final TextStyle titleStyle;
  final TextStyle valueStyle;

  const _BlockField({
    required this.title,
    required this.value,
    required this.titleStyle,
    required this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.trim().isEmpty ? '—' : value.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: titleStyle),
        const SizedBox(height: 6),
        Text(v, style: valueStyle),
      ],
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final Color color;

  const _BlurBlob({required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        height: 260,
        width: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
