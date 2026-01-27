import 'dart:async';
import 'package:nominatim_geocoding/nominatim_geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:traxx_wepapp/models/venue.dart';

/// Helper class for geocoding operations using Nominatim (works on web).
///
/// Provides methods to convert venue addresses to geographic coordinates
/// that can be used with Google Maps.
class GeocodingHelper {
  /// Safely calls the nominatim geocoding API with proper error handling.
  ///
  /// The nominatim_geocoding package has a bug where it throws unhandled
  /// RangeError exceptions in async callbacks when no results are found.
  /// This wrapper catches ALL errors including unhandled async ones.
  static Future<LatLng?> _safeForwardGeoCoding(Address address) async {
    try {
      // Use a completer to handle the result
      final completer = Completer<LatLng?>();

      // Run in a guarded zone to catch unhandled async errors
      runZonedGuarded(() async {
        try {
          final result = await NominatimGeocoding.to.forwardGeoCoding(address);
          final lat = result.coordinate.latitude.toDouble();
          final lng = result.coordinate.longitude.toDouble();
          if (!completer.isCompleted) {
            completer.complete(LatLng(lat, lng));
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      }, (error, stack) {
        // Catch unhandled async errors (like the RangeError from the package)
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      });

      // Wait for result with timeout
      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Geocoding request timed out'),
      );
    } catch (e) {
      // Return null for any error (will be handled by caller)
      return null;
    }
  }

  /// Converts a venue's address to LatLng coordinates.
  ///
  /// Uses the nominatim_geocoding package to translate the venue's full address
  /// into latitude and longitude coordinates suitable for Google Maps.
  ///
  /// Returns null if the address cannot be geocoded (e.g., invalid address,
  /// network issues, or rate limiting).
  ///
  /// Example:
  /// ```dart
  /// final coords = await GeocodingHelper.getCoordinatesFromVenue(venue);
  /// if (coords != null) {
  ///   // Use coords in Google Maps
  /// }
  /// ```
  static Future<LatLng?> getCoordinatesFromVenue(Venue venue) async {
    try {
      final postalCode = int.tryParse(venue.zip) ?? 10000;
      final address1 = Address(
        city: venue.city,
        state: venue.state ?? '', // Provide empty string if null
        postalCode: postalCode,
        country: venue.country,
      );

      final result1 = await _safeForwardGeoCoding(address1);
      if (result1 != null) {
        return result1;
      }
      final address2 = Address(
        city: venue.city,
        postalCode: postalCode,
        country: venue.country,
      );

      final result2 = await _safeForwardGeoCoding(address2);
      if (result2 != null) {
        return result2;
      }

      // Try 3: State and Country (if city is not recognized and state exists)
      if (venue.state != null && venue.state!.isNotEmpty) {
        final stateName = venue.state!;
        final address3 = Address(
          city: stateName, // Use state as city for broader search
          postalCode: postalCode,
          country: venue.country,
        );

        final result3 = await _safeForwardGeoCoding(address3);
        if (result3 != null) {
          return result3;
        }
      }
      final address4 = Address(
        city: venue.country, // Use country as city for ultra-broad search
        postalCode: postalCode,
      );

      final result4 = await _safeForwardGeoCoding(address4);
      if (result4 != null) {
        return result4;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getAddressFromCoordinates(LatLng coordinates) async {
    try {
      final coordinate = Coordinate(
        latitude: coordinates.latitude,
        longitude: coordinates.longitude,
      );

      final result = await NominatimGeocoding.to.reverseGeoCoding(coordinate);

      final address = result.address;
      return '${address.road} ${address.houseNumber}, ${address.city}, ${address.state} ${address.postalCode}, ${address.country}';
    } catch (e) {
      print('Error reverse geocoding coordinates: $e');
      return null;
    }
  }

  /// Creates a Marker for Google Maps from a Venue.
  ///
  /// Returns null if the venue address cannot be geocoded.
  ///
  /// The marker will use the venue's name as the info window title.
  static Future<Marker?> createMarkerFromVenue(Venue venue) async {
    final coordinates = await getCoordinatesFromVenue(venue);
    if (coordinates == null) return null;

    return Marker(
      markerId: MarkerId(venue.venueID ?? 'venue'),
      position: coordinates,
      infoWindow: InfoWindow(
        title: venue.name,
        snippet: venue.fullAddress,
      ),
    );
  }
}
