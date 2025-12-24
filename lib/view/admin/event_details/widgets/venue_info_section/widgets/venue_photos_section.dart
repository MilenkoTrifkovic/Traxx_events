import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/models/venue.dart';

/// Left section widget that displays venue photos in a carousel.
///
/// This widget shows:
/// - "Venue Photos" title
/// - Photo carousel with navigation controls
/// - Empty state when no venue is selected or no photos available
/// - Auto-slides every 3 seconds with looping
class VenuePhotosSection extends StatefulWidget {
  final Venue? venue;

  const VenuePhotosSection({super.key, required this.venue});

  @override
  State<VenuePhotosSection> createState() => _VenuePhotosSectionState();
}

class _VenuePhotosSectionState extends State<VenuePhotosSection> {
  int _currentPhotoIndex = 0;
  Timer? _autoSlideTimer;
  bool _imagesPreloaded = false;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheImages();
  }

  @override
  void didUpdateWidget(VenuePhotosSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart auto-slide if venue changed
    if (oldWidget.venue != widget.venue) {
      _currentPhotoIndex = 0;
      _imagesPreloaded = false;
      _stopAutoSlide();
      _precacheImages();
      _startAutoSlide();
    }
  }

  @override
  void dispose() {
    _stopAutoSlide();
    super.dispose();
  }

  /// Precache all venue images for instant display
  Future<void> _precacheImages() async {
    final photoUrls = widget.venue?.photoUrls ?? [];
    if (photoUrls.isEmpty || !mounted) return;

    try {
      // Precache all images in parallel
      await Future.wait(
        photoUrls.map((url) => precacheImage(NetworkImage(url), context)),
      );

      if (mounted) {
        setState(() {
          _imagesPreloaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error precaching venue images: $e');
      // Continue anyway, images will load on demand
      if (mounted) {
        setState(() {
          _imagesPreloaded = true;
        });
      }
    }
  }

  void _startAutoSlide() {
    _stopAutoSlide(); // Cancel any existing timer

    final photoUrls = widget.venue?.photoUrls ?? [];
    if (photoUrls.isEmpty || photoUrls.length <= 1) {
      return; // No need to auto-slide if 0 or 1 photo
    }

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentPhotoIndex = (_currentPhotoIndex + 1) % photoUrls.length;
        });
      }
    });
  }

  void _stopAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = null;
  }

  void _goToPrevious() {
    final photoUrls = widget.venue?.photoUrls ?? [];
    if (photoUrls.isEmpty) return;

    setState(() {
      _currentPhotoIndex =
          (_currentPhotoIndex - 1 + photoUrls.length) % photoUrls.length;
    });
  }

  void _goToNext() {
    final photoUrls = widget.venue?.photoUrls ?? [];
    if (photoUrls.isEmpty) return;

    setState(() {
      _currentPhotoIndex = (_currentPhotoIndex + 1) % photoUrls.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header
        Text(
          'Venue Photos',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        /// Photo carousel
        widget.venue == null
            ? _buildEmptyPhotoState()
            : _buildPhotoCarousel(widget.venue!),
      ],
    );
  }

  Widget _buildEmptyPhotoState() {
    return Container(
      height: 250,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'No venue selected',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCarousel(Venue venue) {
    final photoUrls = venue.photoUrls;

    if (photoUrls.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'No photos available',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    // Keep index in bounds
    if (_currentPhotoIndex >= photoUrls.length) {
      _currentPhotoIndex = photoUrls.length - 1;
    }

    final currentUrl = photoUrls[_currentPhotoIndex];

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Stack(
        children: [
          // Photo
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _imagesPreloaded
                  ? Image.network(
                      currentUrl,
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // Images are already cached, so they load instantly
                      loadingBuilder: (context, child, loadingProgress) {
                        // Show the image immediately since it's cached
                        return child;
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text(
                                'Failed to load image',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: Colors.grey.shade600,
                              strokeWidth: 2,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loading images...',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // Navigation buttons (only show if multiple photos)
          if (photoUrls.length > 1) ...[
            // Previous button
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  onPressed: _goToPrevious,
                  icon: const Icon(Icons.chevron_left),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9),
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
                  onPressed: _goToNext,
                  icon: const Icon(Icons.chevron_right),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ),
            // Photo counter
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentPhotoIndex + 1} / ${photoUrls.length}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
