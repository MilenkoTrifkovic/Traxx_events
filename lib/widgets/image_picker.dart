import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ReusablePhotoPicker extends StatelessWidget {
  const ReusablePhotoPicker({
    super.key,
    this.xFile,
    this.imageUrl,
    this.imageProvider,
    required this.onPick,
    this.onRemove,
    this.buttonText = "Upload Photo",
    this.displayButton = true,
    this.maxWidth = 360,
    this.borderRadius = 12,
    this.placeholder,
    this.boxFit = BoxFit.cover,
    this.elevation = 0,
  });

  final XFile? xFile;
  final String? imageUrl;
  final ImageProvider? imageProvider;

  // final Future<XFile?> Function() onPick;
  final VoidCallback? Function() onPick;
  final VoidCallback? onRemove;

  final String buttonText;
  final bool displayButton;

  final double maxWidth;
  final double borderRadius;

  final Widget? placeholder;
  final BoxFit boxFit;
  final double elevation;

  ImageProvider? _buildImageProvider() {
    if (imageProvider != null) return imageProvider;
    if (xFile != null) return FileImage(File(xFile!.path));
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return NetworkImage(imageUrl!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // width cannot exceed maxWidth and cannot exceed available space
        final availableWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : maxWidth;

        final width = availableWidth.clamp(0, maxWidth).toDouble();
        final height = width; // aspect ratio 1:1

        final imgProv = _buildImageProvider();

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Material(
              elevation: elevation,
              borderRadius: BorderRadius.circular(borderRadius),
              child: InkWell(
                onTap: () => onPick(),
                borderRadius: BorderRadius.circular(borderRadius),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Stack(
                    children: [
                      Container(
                        width: width,
                        height: height,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: imgProv != null
                            ? Image(
                                image: imgProv,
                                fit: boxFit,
                                width: width,
                                height: height,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholder(context),
                              )
                            : _buildPlaceholder(context),
                      ),

                      // Remove button
                      if (imgProv != null && onRemove != null)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: GestureDetector(
                            onTap: onRemove,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black54,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (displayButton) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: width,
                child: ElevatedButton(
                  onPressed: () => onPick(),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(buttonText),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (placeholder != null) return placeholder!;
    return Center(
      child: Icon(
        Icons.photo_outlined,
        size: 36,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
