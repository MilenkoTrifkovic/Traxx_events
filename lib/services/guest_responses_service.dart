import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/models/demographic_response_model.dart';
import 'package:traxx_wepapp/models/menu_selection_response_model.dart';
import 'package:traxx_wepapp/models/guest_model.dart';

/// Service for fetching and updating guest responses from Firestore
/// Provides clean separation between business logic and data access
class GuestResponsesService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection names
  static const String _demographicResponsesCollection =
      'demographicQuestionsResponses';
  static const String _menuResponsesCollection = 'menuSelectedItemsResponses';

  /// Fetch demographic response for a guest
  ///
  /// Queries the demographicQuestionsResponses collection by guestId and eventId
  /// Returns null if no response is found
  Future<DemographicResponseModel?> fetchDemographicResponse({
    required String guestId,
    required String eventId,
  }) async {
    try {
      print(
          '📋 Fetching demographic response for guest: $guestId, event: $eventId');

      final query = await _db
          .collection(_demographicResponsesCollection)
          .where('guestId', isEqualTo: guestId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print('ℹ️ No demographic response found');
        return null;
      }

      final doc = query.docs.first;
      final data = doc.data();
      data['responseId'] = doc.id; // Add document ID to data

      final response = DemographicResponseModel.fromFirestore(data);
      print('✅ Demographic response found: ${response.answers.length} answers');

      return response;
    } catch (e, stackTrace) {
      print('❌ Error fetching demographic response: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Fetch menu selection response for a guest
  ///
  /// Queries the menuSelectedItemsResponses collection by guestId and eventId
  /// Returns null if no response is found
  Future<MenuSelectionResponseModel?> fetchMenuSelectionResponse({
    required String guestId,
    required String eventId,
  }) async {
    try {
      print(
          '🍽️ Fetching menu selection response for guest: $guestId, event: $eventId');

      final query = await _db
          .collection(_menuResponsesCollection)
          .where('guestId', isEqualTo: guestId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        print('ℹ️ No menu selection response found');
        return null;
      }

      final doc = query.docs.first;
      final data = doc.data();
      data['responseId'] = doc.id; // Add document ID to data

      final response = MenuSelectionResponseModel.fromFirestore(data);
      print(
          '✅ Menu selection response found: ${response.selectedCount} items selected');

      return response;
    } catch (e, stackTrace) {
      print('❌ Error fetching menu selection response: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Update demographic response in Firestore
  ///
  /// Updates an existing response document
  /// Throws exception if update fails
  Future<void> updateDemographicResponse(
    DemographicResponseModel response,
  ) async {
    try {
      print('📝 Updating demographic response: ${response.responseId}');

      await _db
          .collection(_demographicResponsesCollection)
          .doc(response.responseId)
          .update(response.toFirestore());

      print('✅ Demographic response updated successfully');
    } catch (e, stackTrace) {
      print('❌ Error updating demographic response: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Update menu selection response in Firestore
  ///
  /// Updates an existing response document
  /// Throws exception if update fails
  Future<void> updateMenuSelectionResponse(
    MenuSelectionResponseModel response,
  ) async {
    try {
      print('📝 Updating menu selection response: ${response.responseId}');

      await _db
          .collection(_menuResponsesCollection)
          .doc(response.responseId)
          .update(response.toFirestore());

      print('✅ Menu selection response updated successfully');
    } catch (e, stackTrace) {
      print('❌ Error updating menu selection response: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fetch both demographic and menu responses at once
  ///
  /// Convenience method that fetches both responses in parallel
  /// Returns a map with both responses (null if not found)
  Future<Map<String, dynamic>> fetchAllResponses({
    required String guestId,
    required String eventId,
  }) async {
    print('📦 Fetching all responses for guest: $guestId, event: $eventId');

    // Fetch both in parallel for better performance
    final results = await Future.wait([
      fetchDemographicResponse(guestId: guestId, eventId: eventId),
      fetchMenuSelectionResponse(guestId: guestId, eventId: eventId),
    ]);

    return {
      'demographics': results[0],
      'menuSelection': results[1],
    };
  }

  /// Check if guest has submitted demographics
  Future<bool> hasDemographicResponse({
    required String guestId,
    required String eventId,
  }) async {
    try {
      final query = await _db
          .collection(_demographicResponsesCollection)
          .where('guestId', isEqualTo: guestId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking demographic response: $e');
      return false;
    }
  }

  /// Check if guest has submitted menu selection
  Future<bool> hasMenuSelectionResponse({
    required String guestId,
    required String eventId,
  }) async {
    try {
      final query = await _db
          .collection(_menuResponsesCollection)
          .where('guestId', isEqualTo: guestId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking menu selection response: $e');
      return false;
    }
  }

  /// Fetch all guests in a group by groupId
  ///
  /// Returns a list of all guests (main + companions) sharing the same groupId
  /// Returns empty list if no groupId or no guests found
  Future<List<GuestModel>> fetchGroupGuests({
    required String groupId,
    required String eventId,
  }) async {
    try {
      if (groupId.isEmpty) return [];

      final query = await _db
          .collection('guests')
          .where('groupId', isEqualTo: groupId)
          .where('eventId', isEqualTo: eventId)
          .get();

      final guests = query.docs
          .map((doc) => GuestModel.fromFirestore(doc.data(), doc.id))
          .where((g) =>
              g.isDisabled != true) // ✅ local filter (missing field is ok)
          .toList();

      // Sort: main guest first, then companions
      guests.sort((a, b) {
        if (a.isCompanion == b.isCompanion) return 0;
        return a.isCompanion ? 1 : -1;
      });

      return guests;
    } catch (e) {
      print('❌ Error fetching group guests: $e');
      return [];
    }
  }

  /// Fetch responses for all guests in a group
  ///
  /// Returns a map of guestId -> response data
  /// Useful for loading all companion responses at once
  Future<Map<String, Map<String, dynamic>>> fetchGroupResponses({
    required String groupId,
    required String eventId,
  }) async {
    try {
      print('📦 Fetching responses for all guests in group: $groupId');

      // First, get all guests in the group
      final guests = await fetchGroupGuests(
        groupId: groupId,
        eventId: eventId,
      );

      if (guests.isEmpty) {
        print('⚠️ No guests found in group');
        return {};
      }

      // Fetch responses for each guest in parallel
      final responseFutures = guests.map((guest) async {
        final guestId = guest.guestId!;
        final responses = await fetchAllResponses(
          guestId: guestId,
          eventId: eventId,
        );
        return MapEntry(guestId, responses);
      });

      final responsesList = await Future.wait(responseFutures);
      final responsesMap = Map.fromEntries(responsesList);

      print('✅ Loaded responses for ${guests.length} guests');

      return responsesMap;
    } catch (e, stackTrace) {
      print('❌ Error fetching group responses: $e');
      print('Stack trace: $stackTrace');
      return {};
    }
  }
}
