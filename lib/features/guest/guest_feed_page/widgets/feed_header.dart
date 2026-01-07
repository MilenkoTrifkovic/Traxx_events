import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';

/// Header widget for the guest feed page
class FeedHeader extends StatelessWidget {
  final String? eventName;

  const FeedHeader({
    super.key,
    this.eventName,
  });

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md(context),
        vertical: AppSpacing.md(context),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: isPhone ? 40.0 : 48.0,
            height: isPhone ? 40.0 : 48.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF2563EB),
                  Color(0xFF3B82F6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isPhone ? 10 : 12),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF2563EB).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.forum_rounded,
              size: isPhone ? 20.0 : 24.0,
              color: Colors.white,
            ),
          ),
          AppSpacing.horizontalMd(context),
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eventName ?? 'Event Discussion',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isPhone ? 17 : 19,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: -0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'Share your thoughts and connect with others',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isPhone ? 13 : 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
