import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/global_controllers/snackbar_message_controller.dart';

/// PDF Viewer Modal for displaying PDF files
class PdfViewerModal extends StatelessWidget {
  final String pdfUrl;

  const PdfViewerModal({
    super.key,
    required this.pdfUrl,
  });

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
