import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/utils/geocoding_helper.dart';

/// Right section widget that displays venue location on a map.
///
/// This widget shows:
/// - "Venue Location" title
/// - Google Maps with venue marker
class VenueLocationSection extends StatefulWidget {
  final Venue? venue;

  const VenueLocationSection({super.key, this.venue});

  @override
  State<VenueLocationSection> createState() => _VenueLocationSectionState();
}

class _VenueLocationSectionState extends State<VenueLocationSection> {
  GoogleMapController? _mapController;
  LatLng? _venueCoordinates;
  bool _isLoadingCoordinates = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVenueCoordinates();
  }

  @override
  void didUpdateWidget(VenueLocationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.venue?.venueID != widget.venue?.venueID) {
      _loadVenueCoordinates();
    }
  }

  Future<void> _loadVenueCoordinates() async {
    if (widget.venue == null) {
      setState(() {
        _venueCoordinates = null;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoadingCoordinates = true;
      _errorMessage = null;
    });

    try {
      final coordinates =
          await GeocodingHelper.getCoordinatesFromVenue(widget.venue!);

      if (mounted) {
        setState(() {
          _venueCoordinates = coordinates;
          _isLoadingCoordinates = false;
          if (coordinates == null) {
            _errorMessage = 'Could not locate address on map';
          }
        });

        // Animate camera to venue location if map is ready
        if (coordinates != null && _mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(coordinates, 15),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCoordinates = false;
          _errorMessage = 'Error loading location';
        });
      }
    }
  }

  @override
  void dispose() {
    // Don't manually dispose the map controller on web
    // The google_maps_flutter_web plugin manages the controller lifecycle
    // Manually disposing causes "Maps cannot be retrieved before calling buildView!" error
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header
        Text(
          'Venue Location',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),

        /// Map or placeholder
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _buildMapContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildMapContent() {
    // No venue selected
    if (widget.venue == null) {
      return _buildPlaceholder(
        icon: Icons.location_off,
        message: 'No venue selected',
      );
    }

    // Loading coordinates
    if (_isLoadingCoordinates) {
      return _buildPlaceholder(
        icon: Icons.location_searching,
        message: 'Loading location...',
        showProgress: true,
      );
    }

    // Error loading coordinates
    if (_errorMessage != null) {
      return _buildPlaceholder(
        icon: Icons.location_disabled,
        message: _errorMessage!,
        subtitle: widget.venue!.fullAddress,
      );
    }

    // Coordinates loaded successfully
    if (_venueCoordinates != null) {
      return GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _venueCoordinates!,
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: MarkerId(widget.venue!.venueID ?? 'venue'),
            position: _venueCoordinates!,
            infoWindow: InfoWindow(
              title: widget.venue!.name,
              snippet: widget.venue!.fullAddress,
            ),
          ),
        },
        onMapCreated: (controller) {
          _mapController = controller;
        },
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        myLocationButtonEnabled: false,
        compassEnabled: false,
        liteModeEnabled: false,
      );
    }

    // Fallback
    return _buildPlaceholder(
      icon: Icons.location_off,
      message: 'Location not available',
    );
  }

  Widget _buildPlaceholder({
    required IconData icon,
    required String message,
    String? subtitle,
    bool showProgress = false,
  }) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF9FAFB),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            if (showProgress) ...[
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
