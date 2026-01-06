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
                  : Icons.image,
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
