import 'package:flutter/material.dart';
import 'package:traxx_wepapp/controller/admin_controllers/event_details_controllers/image_event_details_controller.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/widgets/buttons/image_action_button.dart';
import 'package:traxx_wepapp/widgets/dialogs/dialogs.dart';
import 'package:traxx_wepapp/widgets/modals/image_viewer_modal.dart';

/// A reusable widget that displays an event's cover image with a placeholder
/// when no image is available or if loading fails.
///
/// The widget displays a bordered, rounded container with the event image
/// or a placeholder icon (wine glass) if the image is not available.
class EventImage extends StatelessWidget {
  final Function(Event) onUpdate;

  /// The event object containing the cover image URL
  final Event event;

  /// The width of the image container
  final double width;

  /// The height of the image container
  final double height;

  /// The border radius of the container
  final double borderRadius;

  /// The icon size for the placeholder
  final double iconSize;

  const EventImage({
    super.key,
    required this.onUpdate,
    required this.event,
    this.width = 48,
    this.height = 48,
    this.borderRadius = 8,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    ImageEventDetailsController controller = ImageEventDetailsController();
    print('EVENT IMAGE URL: ${event.coverImageDownloadUrl}');
    print('EVENT IMAGE PATH: ${event.coverImageUrl}');

    final imageUrl = event.coverImageDownloadUrl;
    final hasImage = imageUrl != null;

    return GestureDetector(
      onTap: hasImage ? () => _showImageModal(context, imageUrl) : null,
      child: MouseRegion(
        cursor: hasImage ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Stack(
          children: [
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: hasImage ? const Color(0xFFE5E7EB) : Colors.red,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                    borderRadius - 2), // Account for border width
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        width:
                            width - 4, // Account for border width on both sides
                        height: height - 4,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildPlaceholder(context),
                      )
                    : _buildPlaceholder(context),
              ),
            ),
            // Overlay gradient for better icon visibility (pointer-transparent)
            if (hasImage)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(borderRadius - 2),
                      gradient: LinearGradient(
                        begin: Alignment.bottomRight,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5],
                      ),
                    ),
                  ),
                ),
              ),
            // Action buttons (stop propagation to prevent opening modal)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {}, // Stop propagation
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit icon - always visible
                    ImageActionButton(
                      icon: Icons.edit_outlined,
                      color: hasImage ? Colors.white : const Color(0xFF3B82F6),
                      backgroundColor: hasImage
                          ? Colors.black.withOpacity(0.5)
                          : Colors.white,
                      onPressed: () {
                        try {
                          controller.uploadEventImage(event, onUpdate);
                        } on Exception catch (e) {
                          // TODO
                        }
                        // TODO: Add edit functionality
                      },
                    ),
                    // Delete icon - only visible when image exists
                    if (hasImage) ...[
                      const SizedBox(width: 6),
                      ImageActionButton(
                        icon: Icons.delete_outline,
                        color: Colors.white,
                        backgroundColor: Colors.black.withOpacity(0.5),
                        onPressed: () {
                          Dialogs.showConfirmationDialog(context,
                              'Are you sure you want to delete this image?',
                              () {
                            controller.deleteEventImage(event);
                          });
                          // TODO: Add delete functionality
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a placeholder widget with a wine glass icon
  /// when the event has no cover image or if image loading fails
  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Icon(
          Icons.wine_bar,
          size: iconSize,
          color: Colors.red,
        ),
      ),
    );
  }

  /// Shows a modal with the full-size image
  void _showImageModal(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return ImageViewerModal(imageUrl: imageUrl);
      },
    );
  }
}
