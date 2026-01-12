import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/guest/guest_feed_page/controller/guest_feed_controller.dart';
import 'package:traxx_wepapp/features/guest/guest_feed_page/widgets/attachment_chip.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/models/message.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/attachment_type.dart';
import 'package:intl/intl.dart';

/// Individual message bubble widget
class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isOwnMessage;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  // bool _isHovering = false; // Temporarily commented out with delete button

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);
    final avatarSize = isPhone ? 32.0 : 40.0;

    // Different styling for own messages vs others
    if (widget.isOwnMessage) {
      return _buildOwnMessage(context, isPhone, avatarSize);
    } else {
      return _buildOtherMessage(context, isPhone, avatarSize);
    }
  }

  /// Build message from other users (left-aligned)
  Widget _buildOtherMessage(
    BuildContext context,
    bool isPhone,
    double avatarSize,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs(context)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: avatarSize / 2,
            backgroundColor: AppColors.primaryAccent.withOpacity(0.1),
            backgroundImage: widget.message.userPhoto != null
                ? NetworkImage(widget.message.userPhoto!)
                : null,
            child: widget.message.userPhoto == null
                ? Icon(
                    Icons.person,
                    size: avatarSize / 2,
                    color: AppColors.primaryAccent,
                  )
                : null,
          ),
          AppSpacing.horizontalSm(context),
          // Message bubble
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and timestamp row with small avatar
                Row(
                  children: [
                    AppText.styledLabelMedium(
                      context,
                      widget.message.userName,
                      color: AppColors.primary,
                      weight: FontWeight.w600,
                    ),
                    AppSpacing.horizontalXxs(context),
                    // Small user photo next to timestamp
                    if (widget.message.userPhoto != null) ...[
                      CircleAvatar(
                        radius: isPhone ? 6.0 : 7.0,
                        backgroundColor: AppColors.primaryAccent.withOpacity(0.1),
                        backgroundImage: NetworkImage(widget.message.userPhoto!),
                      ),
                      AppSpacing.horizontalXxxs(context),
                    ],
                    AppText.styledBodySmall(
                      context,
                      _formatTimestamp(widget.message.createdAt),
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
                AppSpacing.verticalXxs(context),
                // Message content with improved shadow
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md(context),
                    vertical: AppSpacing.sm(context),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isPhone ? 4 : 6),
                      topRight: Radius.circular(isPhone ? 16 : 20),
                      bottomLeft: Radius.circular(isPhone ? 16 : 20),
                      bottomRight: Radius.circular(isPhone ? 16 : 20),
                    ),
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.message.text.isNotEmpty)
                        AppText.styledBodyMedium(
                          context,
                          widget.message.text,
                          color: AppColors.primary,
                        ),
                      // Attachments
                      if (widget.message.attachments.isNotEmpty) ...[
                        if (widget.message.text.isNotEmpty)
                          AppSpacing.verticalSm(context),
                        Wrap(
                          spacing: AppSpacing.xs(context),
                          runSpacing: AppSpacing.xs(context),
                          children: widget.message.attachments.map((attachment) {
                            return AttachmentChip(
                              fileName: attachment.name,
                              type: attachment.type.displayName,
                              attachmentUrl: attachment.url,
                              attachmentType: attachment.type,
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Add spacing for alignment
          SizedBox(width: isPhone ? 40 : 60),
        ],
      ),
    );
  }

  /// Build own message (right-aligned)
  Widget _buildOwnMessage(
    BuildContext context,
    bool isPhone,
    double avatarSize,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs(context)),
      child: MouseRegion(
        // Temporarily commented out with delete button
        // onEnter: (_) => setState(() => _isHovering = true),
        // onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onLongPress: () => _showDeleteConfirmation(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add spacing for alignment
              SizedBox(width: isPhone ? 40 : 60),
              // Message bubble
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Name and timestamp row with small user photo
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Delete button (visible on hover for desktop)
                        // Temporarily hidden - uncomment to enable
                        // AnimatedOpacity(
                        //   opacity: _isHovering ? 1.0 : 0.0,
                        //   duration: Duration(milliseconds: 200),
                        //   child: InkWell(
                        //     onTap: _isHovering
                        //         ? () => _showDeleteConfirmation(context)
                        //         : null,
                        //     borderRadius: BorderRadius.circular(4),
                        //     child: Padding(
                        //       padding: EdgeInsets.symmetric(
                        //         horizontal: AppSpacing.xs(context),
                        //         vertical: 2,
                        //       ),
                        //       child: Icon(
                        //         Icons.delete_outline,
                        //         size: isPhone ? 16 : 18,
                        //         color: AppColors.inputError,
                        //       ),
                        //     ),
                        //   ),
                        // ),
                        // if (_isHovering) AppSpacing.horizontalXxxs(context),
                        AppText.styledBodySmall(
                          context,
                          _formatTimestamp(widget.message.createdAt),
                          color: AppColors.textMuted,
                        ),
                        // Small user photo next to timestamp
                        if (widget.message.userPhoto != null) ...[
                          AppSpacing.horizontalXxxs(context),
                          CircleAvatar(
                            radius: isPhone ? 6.0 : 7.0,
                            backgroundColor: AppColors.primaryAccent.withOpacity(0.2),
                            backgroundImage: NetworkImage(widget.message.userPhoto!),
                          ),
                        ],
                        AppSpacing.horizontalXxs(context),
                        AppText.styledLabelMedium(
                          context,
                          widget.message.userName,
                          color: AppColors.primary,
                          weight: FontWeight.w600,
                        ),
                      ],
                    ),
                    AppSpacing.verticalXxs(context),
                    // Message content with improved shadow
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.md(context),
                        vertical: AppSpacing.sm(context),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(isPhone ? 16 : 20),
                          topRight: Radius.circular(isPhone ? 4 : 6),
                          bottomLeft: Radius.circular(isPhone ? 16 : 20),
                          bottomRight: Radius.circular(isPhone ? 16 : 20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryAccent.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.message.text.isNotEmpty)
                            AppText.styledBodyMedium(
                              context,
                              widget.message.text,
                              color: AppColors.white,
                            ),
                          // Attachments
                          if (widget.message.attachments.isNotEmpty) ...[
                            if (widget.message.text.isNotEmpty)
                              AppSpacing.verticalSm(context),
                            Wrap(
                              spacing: AppSpacing.xs(context),
                              runSpacing: AppSpacing.xs(context),
                              children:
                                  widget.message.attachments.map((attachment) {
                                return AttachmentChip(
                                  fileName: attachment.name,
                                  type: attachment.type.displayName,
                                  attachmentUrl: attachment.url,
                                  attachmentType: attachment.type,
                                  isOwnMessage: true,
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.horizontalSm(context),
              // Avatar
              CircleAvatar(
                radius: avatarSize / 2,
                backgroundColor: AppColors.primaryAccent.withOpacity(0.2),
                backgroundImage: widget.message.userPhoto != null
                    ? NetworkImage(widget.message.userPhoto!)
                    : null,
                child: widget.message.userPhoto == null
                    ? Icon(
                        Icons.person,
                        size: avatarSize / 2,
                        color: AppColors.primaryAccent,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a confirmation dialog before deleting the message
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Message',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.secondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _deleteMessage(context);
            },
            child: Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.inputError,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Deletes the message using the controller
  void _deleteMessage(BuildContext context) {
    if (widget.message.messageId == null) {
      print('Cannot delete message: messageId is null');
      return;
    }

    try {
      // Find the controller using the eventId from the message's context
      // We need to get the controller from the widget tree
      final controller = Get.find<GuestFeedController>();
      controller.deleteMessage(widget.message.messageId!);
      
      // Optional: Show a success message
      print('✅ Message deleted successfully');
    } catch (e) {
      print('❌ Error deleting message: $e');
      // TODO: Show error to user
    }
  }
}
