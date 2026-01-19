import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

class SidebarStyleTopHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  // Organisation (optional)
  final String? organisationName;
  final String? organisationPhotoUrl;

  // Leading (optional)
  final VoidCallback? onBack;
  final String backText;

  // Middle slot (optional) e.g. search field
  final Widget? middle;

  // Right actions
  final List<Widget> actions;

  const SidebarStyleTopHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.organisationName,
    this.organisationPhotoUrl,
    this.onBack,
    this.backText = 'Back',
    this.middle,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = ScreenSize.isDesktop(context);
    final w = MediaQuery.of(context).size.width;

    // Consider "compact" if narrow (or when sidebar is collapsed)
    final compact = w < 980;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 22 : 16,
          14,
          isDesktop ? 22 : 16,
          14,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary, // same as Sidebar
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border(
            bottom: BorderSide(
              color: Colors.white.withOpacity(0.10),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              // Leading: Back (optional)
              if (onBack != null) ...[
                _HeaderBackButton(
                  onTap: onBack!,
                  text: backText,
                  showText: isDesktop && !compact,
                ),
                const SizedBox(width: 14),
              ],

              // Organisation block (optional)
              if ((organisationName ?? '').trim().isNotEmpty ||
                  organisationPhotoUrl != null)
                _OrgBlock(
                  compact: compact,
                  organisationName: organisationName ?? '',
                  organisationPhotoUrl: organisationPhotoUrl,
                ),

              if ((organisationName ?? '').trim().isNotEmpty ||
                  organisationPhotoUrl != null)
                const SizedBox(width: 14),

              // Title/Sub + optional middle widget
              Expanded(
                child: Row(
                  children: [
                    // Title area
                    Expanded(
                      child: _TitleBlock(
                        title: title,
                        subtitle: subtitle,
                        compact: compact,
                      ),
                    ),

                    // Middle slot (optional) e.g. search
                    if (middle != null) ...[
                      const SizedBox(width: 14),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: compact ? 280 : 420,
                        ),
                        child: middle!,
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: actions,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrgBlock extends StatelessWidget {
  final bool compact;
  final String organisationName;
  final String? organisationPhotoUrl;

  const _OrgBlock({
    required this.compact,
    required this.organisationName,
    this.organisationPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: Colors.white,
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
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.auto_awesome,
                      color: AppColors.primary,
                      size: compact ? 18 : 22,
                    ),
                  )
                : Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                    size: compact ? 18 : 22,
                  ),
          ),
        ),
        if (!compact && organisationName.trim().isNotEmpty) ...[
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              organisationName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool compact;

  const _TitleBlock({
    required this.title,
    this.subtitle,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        if ((subtitle ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.70),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  final VoidCallback onTap;
  final String text;
  final bool showText;

  const _HeaderBackButton({
    required this.onTap,
    required this.text,
    required this.showText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withOpacity(0.10),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            if (showText) ...[
              const SizedBox(width: 8),
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
