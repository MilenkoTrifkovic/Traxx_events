import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/widgets/dialogs/app_dialog.dart';

class VenueDetailsDialog extends StatefulWidget {
  final Venue venue;

  const VenueDetailsDialog({super.key, required this.venue});

  @override
  State<VenueDetailsDialog> createState() => _VenueDetailsDialogState();
}

class _VenueDetailsDialogState extends State<VenueDetailsDialog> {
  late int _currentImageIndex;
  late List<String> _imageUrls;

  @override
  void initState() {
    super.initState();
    _currentImageIndex = 0;

    // Get all available image URLs
    _imageUrls = [];
    if (widget.venue.photoUrls != null && widget.venue.photoUrls!.isNotEmpty) {
      _imageUrls = widget.venue.photoUrls!;
    } else if (widget.venue.photoUrl != null &&
        widget.venue.photoUrl!.isNotEmpty) {
      _imageUrls = [widget.venue.photoUrl!];
    }
  }

  void _nextImage() {
    if (_imageUrls.isNotEmpty) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + 1) % _imageUrls.length;
      });
    }
  }

  void _previousImage() {
    if (_imageUrls.isNotEmpty) {
      setState(() {
        _currentImageIndex =
            (_currentImageIndex - 1 + _imageUrls.length) % _imageUrls.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget imageSection() {
      if (_imageUrls.isEmpty) {
        return _noImagePlaceholder(context);
      }

      final currentUrl = _imageUrls[_currentImageIndex];
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Image.network(
                currentUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _noImagePlaceholder(context),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    child: Center(
                      child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  (progress.expectedTotalBytes ?? 1)
                              : null),
                    ),
                  );
                },
              ),
              // Navigation arrows (only show if multiple images)
              if (_imageUrls.length > 1) ...[
                // Previous button
                Positioned(
                  left: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: _previousImage,
                      icon: const Icon(Icons.arrow_back_ios),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ),
                // Next button
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: IconButton(
                      onPressed: _nextImage,
                      icon: const Icon(Icons.arrow_forward_ios),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black54,
                      ),
                    ),
                  ),
                ),
                // Image counter
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppText.styledBodySmall(
                      context,
                      '${_currentImageIndex + 1} / ${_imageUrls.length}',
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return AppDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image or placeholder
          imageSection(),

          AppSpacing.verticalXs(context),

          // Category
          Padding(
            padding: AppPadding.horizontal(context, paddingType: Sizes.xs),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                AppText.styledHeadingMedium(context, widget.venue.name,
                    weight: AppFontWeight.bold, color: AppColors.black),
                AppSpacing.horizontalXs(context),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    AppSpacing.horizontalXs(context),
                    Expanded(
                      child: Padding(
                        padding: AppPadding.only(context,
                            paddingType: Sizes.xs, right: true),
                        child: AppText.styledBodyMedium(
                          context,
                          widget.venue.fullAddress,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.description, size: 16),
                    AppSpacing.horizontalXs(context),
                    if (widget.venue.description != null &&
                        widget.venue.description!.isNotEmpty)
                      Flexible(
                        child: Padding(
                          padding: AppPadding.only(context,
                              paddingType: Sizes.xs, right: true),
                          child: AppText.styledBodyMedium(
                            context,
                            widget.venue.description!,
                          ),
                        ),
                      ),
                  ],
                ),
                // Chip(
                //   label: AppText.styledBodyMedium(
                //       context, _prettyCategory(venue.name.capitalize),
                //       weight: AppFontWeight.semiBold),
                // ),
              ],
            ),
          ),

          AppSpacing.verticalXs(context),

          // Description
        ],
      ),
    );
  }

  Widget _noImagePlaceholder(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_not_supported,
                  size: 48, color: Theme.of(context).hintColor),
              const SizedBox(height: 8),
              Text('No image available',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
