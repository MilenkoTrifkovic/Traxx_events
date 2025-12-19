import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/models/venue.dart';

/// Left section widget that displays venue photos in a carousel.
///
/// This widget shows:
/// - "Venue Photos" title
/// - Photo carousel with navigation controls
/// - Empty state when no venue is selected or no photos available
class VenuePhotosSection extends StatefulWidget {
  final Venue? venue;

  const VenuePhotosSection({super.key, required this.venue});

  @override
  State<VenuePhotosSection> createState() => _VenuePhotosSectionState();
}

class _VenuePhotosSectionState extends State<VenuePhotosSection> {
  int _currentPhotoIndex = 0;

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
              child: Image.network(
                currentUrl,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
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
                  onPressed: _currentPhotoIndex > 0
                      ? () {
                          setState(() {
                            _currentPhotoIndex--;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    disabledBackgroundColor: Colors.grey.shade300,
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
                  onPressed: _currentPhotoIndex < photoUrls.length - 1
                      ? () {
                          setState(() {
                            _currentPhotoIndex++;
                          });
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    disabledBackgroundColor: Colors.grey.shade300,
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
