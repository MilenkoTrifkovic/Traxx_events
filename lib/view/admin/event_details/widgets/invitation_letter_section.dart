import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/admin_controllers/event_details_controllers/invitation_letter_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/dialogs/dialogs.dart';
import 'package:traxx_wepapp/widgets/modals/image_viewer_modal.dart';

/// Invitation letter section for event details.
/// Allows users to upload PDF or image files for email invitations.
class InvitationLetterSection extends StatelessWidget {
  final Event event;
  
  const InvitationLetterSection({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(InvitationLetterController());
    
    // Initialize controller with event data
    controller.initializeWithEvent(event);

    return Container(
      padding: EdgeInsets.all(AppSpacing.sm(context)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryAccent.withOpacity(0.1),
                      AppColors.primaryAccent.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insert_drive_file_outlined,
                  size: 24,
                  color: AppColors.primaryAccent,
                ),
              ),
              SizedBox(width: AppSpacing.xs(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invitation Letter',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: AppFontWeight.semiBold,
                        color: AppColors.primary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Upload PDF or image for email invitations',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: AppFontWeight.regular,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: AppSpacing.sm(context)),

          // Content area - shows uploaded file, local file, or upload area
          Obx(() {
            // Case 1: Has uploaded file (from Firebase)
            if (controller.hasUploadedFile()) {
              return _buildUploadedFilePreview(context, controller);
            }
            // Case 2: Has local file selected (not yet uploaded)
            else if (controller.hasLocalFile()) {
              return Column(
                children: [
                  _buildLocalFilePreview(controller),
                  const SizedBox(height: 12),
                  _buildUploadButton(controller),
                ],
              );
            }
            // Case 3: No file selected
            else {
              return _buildUploadArea(controller);
            }
          }),

          // Error message
          Obx(() {
            if (controller.errorMessage.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  controller.errorMessage.value,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  /// Build upload area when no file is selected
  Widget _buildUploadArea(InvitationLetterController controller) {
    return Obx(() => controller.isLoading.value
        ? Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: AppFontWeight.medium,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          )
        : MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => controller.pickInvitationFile(),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryAccent.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Stack(
                  children: [
                    // Dashed border effect
                    Positioned.fill(
                      child: CustomPaint(
                        painter: DashedBorderPainter(
                          color: AppColors.primaryAccent.withOpacity(0.4),
                          strokeWidth: 2,
                          dashWidth: 8,
                          dashSpace: 6,
                        ),
                      ),
                    ),
                    // Content
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Drop file here or click to browse',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: AppFontWeight.semiBold,
                              color: AppColors.primary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Supports: PDF, JPG, PNG',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: AppFontWeight.regular,
                              color: AppColors.textMuted,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Max file size: 10MB',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: AppFontWeight.regular,
                              color: AppColors.textMuted.withOpacity(0.8),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ));
  }

  /// Build file preview when a file is selected locally
  Widget _buildLocalFilePreview(InvitationLetterController controller) {
    final file = controller.invitationFile.value!;
    final isPdf = controller.isPdf();

    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryAccent.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // File icon with gradient background
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPdf
                        ? [
                            const Color(0xFFDC2626).withOpacity(0.15),
                            const Color(0xFFDC2626).withOpacity(0.05),
                          ]
                        : [
                            AppColors.primaryAccent.withOpacity(0.15),
                            AppColors.primaryAccent.withOpacity(0.05),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                  size: 28,
                  color: isPdf ? const Color(0xFFDC2626) : AppColors.primaryAccent,
                ),
              ),

              SizedBox(width: AppSpacing.xs(context)),

              // File info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBBF24).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ready to upload',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: AppFontWeight.semiBold,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      file.name,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: AppFontWeight.medium,
                        color: AppColors.primary,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.getFileSize(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: AppFontWeight.regular,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: AppSpacing.xs(context)),

              // Action buttons
              Row(
                children: [
                  // Replace button
                  _buildIconButton(
                    icon: Icons.refresh,
                    tooltip: 'Change file',
                    onPressed: () => controller.pickInvitationFile(),
                    color: AppColors.textMuted,
                  ),

                  const SizedBox(width: 4),

                  // Remove button
                  _buildIconButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Remove',
                    onPressed: () => controller.removeFile(),
                    color: const Color(0xFFDC2626),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build upload button for local file
  Widget _buildUploadButton(InvitationLetterController controller) {
    return Obx(() => AppPrimaryButton(
          text: controller.isUploading.value ? 'Uploading...' : 'Upload Invitation Letter',
          icon: controller.isUploading.value ? null : Icons.cloud_upload,
          onPressed: controller.isUploading.value
              ? null
              : () => controller.uploadAndSaveInvitationLetter(),
          isLoading: controller.isUploading.value,
          width: double.infinity,
          height: 48,
        ));
  }

  /// Build preview for uploaded file from Firebase Storage
  Widget _buildUploadedFilePreview(BuildContext context, InvitationLetterController controller) {
    final extension = controller.invitationLetterPath.value.split('.').last.toLowerCase();
    final isPdf = extension == 'pdf';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withOpacity(0.08),
            const Color(0xFF10B981).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // File icon with success indicator
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPdf
                        ? [
                            const Color(0xFFDC2626).withOpacity(0.15),
                            const Color(0xFFDC2626).withOpacity(0.05),
                          ]
                        : [
                            AppColors.primaryAccent.withOpacity(0.15),
                            AppColors.primaryAccent.withOpacity(0.05),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                  size: 28,
                  color: isPdf ? const Color(0xFFDC2626) : AppColors.primaryAccent,
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(width: AppSpacing.xs(context)),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_done,
                            size: 12,
                            color: const Color(0xFF059669),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Uploaded Invitation Letter',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: AppFontWeight.semiBold,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  controller.invitationLetterPath.value.split('/').last,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: AppFontWeight.medium,
                    color: AppColors.primary,
                    height: 1.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Ready for email invitations',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: AppFontWeight.regular,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: AppSpacing.xs(context)),

          // Action buttons
          Row(
            children: [
              // View button
              _buildIconButton(
                icon: Icons.visibility_outlined,
                tooltip: 'View file',
                onPressed: () => _openFileInModal(
                  context,
                  controller.invitationLetterUrl.value,
                  isPdf,
                ),
                color: AppColors.primaryAccent,
                isPrimary: true,
              ),

              const SizedBox(width: 4),

              // Replace button
              _buildIconButton(
                icon: Icons.swap_horiz,
                tooltip: 'Replace file',
                onPressed: () => controller.pickInvitationFile(),
                color: AppColors.textMuted,
              ),

              const SizedBox(width: 4),

              // Delete button
              Obx(() => _buildIconButton(
                    icon: Icons.delete_outline,
                    tooltip: 'Delete file',
                    onPressed: controller.isUploading.value
                        ? null
                        : () => _confirmDelete(context, controller),
                    color: const Color(0xFFDC2626),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  /// Build icon button with consistent styling
  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    required Color color,
    bool isPrimary = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPrimary
                ? color.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null ? color.withOpacity(0.4) : color,
          ),
        ),
      ),
    );
  }

  /// Open file in modal popup
  void _openFileInModal(BuildContext context, String url, bool isPdf) {
    if (isPdf) {
      // Show PDF viewer modal
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => _PdfViewerModal(pdfUrl: url),
      );
    } else {
      // Show image viewer modal
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => ImageViewerModal(imageUrl: url),
      );
    }
  }

  /// Confirm deletion dialog
  void _confirmDelete(BuildContext context, InvitationLetterController controller) {
    Dialogs.showConfirmationDialog(
      context,
      'This will permanently remove the invitation letter from cloud storage. This action cannot be undone.',
      () => controller.deleteInvitationLetter(),
      title: 'Delete Invitation Letter?',
    );
  }
}

/// PDF Viewer Modal for displaying PDF files
class _PdfViewerModal extends StatelessWidget {
  final String pdfUrl;

  const _PdfViewerModal({required this.pdfUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            // PDF Viewer - Using iframe for web
            Center(
              child: GestureDetector(
                onTap: () {}, // Prevent tap from propagating to background
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red.shade400,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'PDF Preview',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _openInNewTab(pdfUrl),
                                icon: const Icon(Icons.open_in_new),
                                tooltip: 'Open in new tab',
                                color: const Color(0xFF6366F1),
                              ),
                            ],
                          ),
                        ),
                        
                        // PDF Content
                        Expanded(
                          child: Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.picture_as_pdf,
                                    size: 64,
                                    color: Colors.red.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'PDF File',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32),
                                    child: Text(
                                      'Click "Open in new tab" to view the PDF',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: const Color(0xFF6B7280),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () => _openInNewTab(pdfUrl),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    icon: const Icon(Icons.open_in_new, size: 20),
                                    label: Text(
                                      'Open PDF',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: const Color(0xFF6B7280),
                  tooltip: 'Close',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Open PDF in new tab/window
  void _openInNewTab(String url) {
    // For web, use window.open
    // For now, just show info (you can implement actual opening logic)
    final snackbarController = Get.find<SnackbarMessageController>();
    snackbarController.showInfoMessage('Opening PDF in new tab');
    
    // TODO: Implement platform-specific file opening
    // For web: import 'dart:html' as html; html.window.open(url, '_blank');
    // For mobile: import 'package:url_launcher/url_launcher.dart'; launchUrl(Uri.parse(url));
  }
}

/// Custom painter for dashed border effect
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        const Radius.circular(12),
      ));

    final dashPath = _createDashedPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, double dashWidth, double dashSpace) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        if (distance + length > metric.length) {
          if (draw) {
            dest.addPath(
              metric.extractPath(distance, metric.length),
              Offset.zero,
            );
          }
          break;
        }
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
