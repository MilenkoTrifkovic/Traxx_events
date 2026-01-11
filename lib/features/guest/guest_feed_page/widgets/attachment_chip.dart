import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/attachment_type.dart';
import 'package:url_launcher/url_launcher.dart';

/// Chip widget for displaying attachments
class AttachmentChip extends StatelessWidget {
  final String fileName;
  final String type;
  final String attachmentUrl;
  final AttachmentType attachmentType;
  final bool isOwnMessage;

  const AttachmentChip({
    super.key,
    required this.fileName,
    required this.type,
    required this.attachmentUrl,
    required this.attachmentType,
    this.isOwnMessage = false,
  });

  /// Opens the attachment based on its type
  Future<void> _openAttachment(BuildContext context) async {
    try {
      if (attachmentType == AttachmentType.pdf) {
        // Open PDF in browser or external viewer
        final uri = Uri.parse(attachmentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          print('Could not launch PDF: $attachmentUrl');
          // TODO: Show error to user
        }
      } else if (attachmentType == AttachmentType.image) {
        // Show image in a dialog/viewer
        _showImageViewer(context);
      }
    } catch (e) {
      print('Error opening attachment: $e');
      // TODO: Show error to user
    }
  }

  /// Shows image in a full-screen viewer dialog
  void _showImageViewer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Image
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  attachmentUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppColors.white,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: AppColors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.close, color: AppColors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);

    // For images, show thumbnail
    if (attachmentType == AttachmentType.image) {
      return _buildImageThumbnail(context, isPhone);
    }

    // For other files (PDF, etc.), show chip with icon
    return _buildFileChip(context, isPhone);
  }

  /// Builds an image thumbnail for image attachments
  Widget _buildImageThumbnail(BuildContext context, bool isPhone) {
    // Use wider thumbnails that fit nicely in chat bubbles
    final thumbnailWidth = isPhone ? 200.0 : 240.0;
    final thumbnailHeight = isPhone ? 150.0 : 180.0;

    return InkWell(
      onTap: () => _openAttachment(context),
      borderRadius: BorderRadius.circular(isPhone ? 12 : 16),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: thumbnailWidth,
          maxHeight: thumbnailHeight,
        ),
        child: Stack(
          children: [
            // Image container with rounded corners
            ClipRRect(
              borderRadius: BorderRadius.circular(isPhone ? 12 : 16),
              child: Container(
                width: thumbnailWidth,
                height: thumbnailHeight,
                decoration: BoxDecoration(
                  color: isOwnMessage
                      ? AppColors.white.withOpacity(0.08)
                      : AppColors.borderSubtle.withOpacity(0.3),
                ),
                child: Image.network(
                  attachmentUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      // Image loaded successfully
                      return child;
                    }
                    // Show elegant loading state with placeholder icon
                    return Container(
                      color: isOwnMessage
                          ? AppColors.white.withOpacity(0.08)
                          : AppColors.surfaceCard,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Large image placeholder icon
                            Icon(
                              Icons.image_outlined,
                              color: isOwnMessage
                                  ? AppColors.white.withOpacity(0.3)
                                  : AppColors.textMuted.withOpacity(0.3),
                              size: isPhone ? 48 : 56,
                            ),
                            SizedBox(height: 12),
                            // Circular progress indicator
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: isOwnMessage
                                    ? AppColors.white.withOpacity(0.7)
                                    : AppColors.primaryAccent,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: isOwnMessage
                          ? AppColors.white.withOpacity(0.08)
                          : AppColors.surfaceCard,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              color: isOwnMessage
                                  ? AppColors.white.withOpacity(0.5)
                                  : AppColors.textMuted.withOpacity(0.5),
                              size: isPhone ? 32 : 40,
                            ),
                            SizedBox(height: 8),
                            AppText.styledBodySmall(
                              context,
                              'Image unavailable',
                              color: isOwnMessage
                                  ? AppColors.white.withOpacity(0.6)
                                  : AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Subtle gradient overlay at bottom for better filename readability
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(isPhone ? 12 : 16),
                    bottomRight: Radius.circular(isPhone ? 12 : 16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.black.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),
            // Filename badge at bottom
            Positioned(
              bottom: 6,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  // File icon
                  Icon(
                    Icons.photo,
                    size: isPhone ? 12 : 14,
                    color: AppColors.white,
                  ),
                  SizedBox(width: 4),
                  // Filename
                  Expanded(
                    child: Text(
                      fileName,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isPhone ? 11 : 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                        shadows: [
                          Shadow(
                            color: AppColors.black.withOpacity(0.5),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Tap to view indicator (top right)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.zoom_in,
                      size: isPhone ? 12 : 14,
                      color: AppColors.white,
                    ),
                    SizedBox(width: 2),
                    Text(
                      'View',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: isPhone ? 10 : 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a file chip for non-image attachments (PDF, etc.)
  Widget _buildFileChip(BuildContext context, bool isPhone) {
    return InkWell(
      onTap: () => _openAttachment(context),
      borderRadius: BorderRadius.circular(isPhone ? 6 : 8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm(context),
          vertical: AppSpacing.xs(context),
        ),
        decoration: BoxDecoration(
          color: isOwnMessage
              ? AppColors.white.withOpacity(0.2)
              : AppColors.chipBackground,
          borderRadius: BorderRadius.circular(isPhone ? 6 : 8),
          border: Border.all(
            color: isOwnMessage
                ? AppColors.white.withOpacity(0.3)
                : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              attachmentType == AttachmentType.pdf
                  ? Icons.picture_as_pdf
                  : Icons.attach_file,
              size: isPhone ? 14 : 16,
              color: isOwnMessage ? AppColors.white : AppColors.primaryAccent,
            ),
            AppSpacing.horizontalXxxs(context),
            Flexible(
              child: AppText.styledBodySmall(
                context,
                fileName,
                color: isOwnMessage ? AppColors.white : AppColors.primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            AppSpacing.horizontalXxxs(context),
            AppText.styledMetaSmall(
              context,
              type,
              color: isOwnMessage
                  ? AppColors.white.withOpacity(0.8)
                  : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
