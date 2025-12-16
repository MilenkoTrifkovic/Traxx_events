import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traxx_wepapp/controller/global_controllers/venues_controller.dart';

/// A widget that manages venue selection and photo management for events.
///
/// This widget allows users to:
/// - Select a venue from a dropdown
/// - View venue photos in a carousel
/// - Add new photos to the venue (immediate upload and save)
/// - Remove existing photos from the venue (immediate delete)
///
/// **Important**:
/// - Changes to venue photos affect ALL events using that venue
/// - All photo operations (add/remove) happen IMMEDIATELY, independent of dialog save
/// - Photos are NOT tied to the save button - they update the venue directly
class VenuePhotoManager extends StatefulWidget {
  final String? initialVenueId;
  final ValueChanged<String?> onVenueSelected;

  const VenuePhotoManager({
    super.key,
    this.initialVenueId,
    required this.onVenueSelected,
  });

  @override
  State<VenuePhotoManager> createState() => _VenuePhotoManagerState();
}

class _VenuePhotoManagerState extends State<VenuePhotoManager> {
  late String? _selectedVenueId;
  int _currentPhotoIndex = 0;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _selectedVenueId = widget.initialVenueId;
  }

  void _onVenueChanged(String? newVenueId) {
    setState(() {
      _selectedVenueId = newVenueId;
      _currentPhotoIndex = 0;
    });
    widget.onVenueSelected(newVenueId);
  }

  Future<void> _addPhotos() async {
    if (_isProcessing || _selectedVenueId == null) return;

    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final venuesController = Get.find<VenuesController>();
      final venue = venuesController.venues.firstWhereOrNull(
        (v) => v.venueID == _selectedVenueId,
      );

      if (venue == null) {
        throw Exception('Venue not found');
      }

      // Get current photo paths
      final currentPhotoPaths = List<String>.from(venue.photoPaths ?? []);

      // Add new photo paths (these are local file paths that will be uploaded)
      final newPaths = images.map((xfile) => xfile.path).toList();
      currentPhotoPaths.addAll(newPaths);

      // Update venue with new photo paths
      final updatedVenue = venue.copyWith(photoPaths: currentPhotoPaths);
      print('Venue ready for update is ${updatedVenue.toString()}');
      await venuesController.updateVenue(updatedVenue);

      // Reload venue to get updated photoUrls (after upload)
      await venuesController.fetchVenueById(_selectedVenueId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${images.length} photo(s) added successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add photos: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _removeCurrentPhoto(String photoUrl) async {
    if (_isProcessing) return; // Prevent multiple simultaneous operations

    final venuesController = Get.find<VenuesController>();
    final venue = venuesController.venues.firstWhereOrNull(
      (v) => v.venueID == _selectedVenueId,
    );

    if (venue == null) return;

    // Find the index of the current photo in photoUrls
    final photoUrls = venue.photoUrls ?? [];
    final photoIndex = photoUrls.indexOf(photoUrl);

    if (photoIndex == -1) return; // Photo not found

    // Make sure we have photoPaths and the index is valid
    final photoPaths = venue.photoPaths ?? [];
    if (photoIndex >= photoPaths.length) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Remove from venue's photoPaths at the same index
      final updatedPhotoPaths = List<String>.from(photoPaths);
      updatedPhotoPaths.removeAt(photoIndex);

      // Update venue in Firestore immediately
      final updatedVenue = venue.copyWith(photoPaths: updatedPhotoPaths);
      print('Venue ready for update is ${updatedVenue.toString()}');
      await venuesController.updateVenue(updatedVenue);

      // Reload venue to get updated photoUrls
      await venuesController.fetchVenueById(_selectedVenueId!);

      // Adjust photo index if needed
      if (_currentPhotoIndex > 0 &&
          _currentPhotoIndex >= (updatedPhotoPaths.length)) {
        setState(() {
          _currentPhotoIndex = updatedPhotoPaths.length - 1;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo removed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove photo: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final venuesController = Get.find<VenuesController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Venue Selection Dropdown
        Obx(() {
          final venues = venuesController.venues;
          return DropdownButtonFormField<String>(
            value: _selectedVenueId,
            decoration: const InputDecoration(
              labelText: 'Venue',
            ),
            items: venues.map((venue) {
              return DropdownMenuItem<String>(
                value: venue.venueID,
                child: Text(venue.name.capitalize ?? venue.name),
              );
            }).toList(),
            onChanged: _onVenueChanged,
          );
        }),
        const SizedBox(height: 20),
        // Venue Photos Section
        if (_selectedVenueId != null)
          _buildVenuePhotosSection(venuesController),
      ],
    );
  }

  Widget _buildVenuePhotosSection(VenuesController venuesController) {
    final venue = venuesController.venues.firstWhereOrNull(
      (v) => v.venueID == _selectedVenueId,
    );

    if (venue == null) {
      return const SizedBox.shrink();
    }

    // Get current photos from venue (reactive)
    final currentPhotoUrls = venue.photoUrls ?? [];
    final displayPhotos = currentPhotoUrls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warning message
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            border: Border.all(color: Colors.orange.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber,
                  color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Warning: Changes to venue photos will affect ALL events at this venue',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Venue Photos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            ElevatedButton.icon(
              onPressed: _addPhotos,
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: const Text('Add Photos'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Photo carousel
        if (displayPhotos.isEmpty)
          Container(
            height: 200,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined,
                    size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'No photos yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          )
        else
          _buildPhotoCarousel(displayPhotos),
      ],
    );
  }

  Widget _buildPhotoCarousel(List<String> photoUrls) {
    if (photoUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    // Keep index in bounds
    if (_currentPhotoIndex >= photoUrls.length) {
      _currentPhotoIndex = photoUrls.length - 1;
    }

    final currentUrl = photoUrls[_currentPhotoIndex];

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // Photo
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                currentUrl,
                height: 300,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text('Failed to load image',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          // Navigation buttons
          if (photoUrls.length > 1) ...[
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
              bottom: 8,
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
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
          // Delete button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => _removeCurrentPhoto(currentUrl),
              icon: const Icon(Icons.delete),
              style: IconButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.9),
                foregroundColor: Colors.white,
              ),
              tooltip: 'Remove this photo',
            ),
          ),
        ],
      ),
    );
  }
}
