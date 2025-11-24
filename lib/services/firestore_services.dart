import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/helper/firestore_helper.dart';
import 'package:traxx_wepapp/models/guest.dart';
import 'package:traxx_wepapp/models/event_questions.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/guest_response.dart';
import 'package:traxx_wepapp/models/menu_old.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/utils/collect_ref.dart';
import 'package:traxx_wepapp/utils/enums/input_type.dart';
import 'package:traxx_wepapp/models/menu_item.dart' as new_menu;

class FirestoreServices {
  final _db = FirebaseFirestore.instance;

  /// Reference to users collection in Firestore
  late final CollectionReference<Map<String, dynamic>> usersRef;

  /// Reference to events collection in Firestore
  late final CollectionReference<Map<String, dynamic>> eventsRef;

  /// Reference to locations collection in Firestore
  late final CollectionReference<Map<String, dynamic>> locationsRef;

  /// Reference to organisations collection in Firestore
  late final CollectionReference<Organisation> organisationsRef;

  /// Reference to venues collection in Firestore
  late final CollectionReference<Venue> venuesRef;

  final CollectionReference<Map<String, dynamic>> menuItemsRef =
      FirebaseFirestore.instance.collection('menu_items');

  FirestoreServices() {
    usersRef = _db.collection(usersCol);
    eventsRef = _db.collection(eventsCol);
    locationsRef = _db.collection(locationsCol);
    organisationsRef =
        _db.collection(organisationCol).withConverter<Organisation>(
              fromFirestore: (snap, _) => Organisation.fromFirestore(snap),
              toFirestore: (value, _) => value.toFirestore(),
            );
    venuesRef = _db.collection(venuesCol).withConverter<Venue>(
          fromFirestore: (snap, _) => Venue.fromFirestore(snap),
          toFirestore: (value, _) => value.toFirestore(),
        );
  }

  /// Adds a new organisation to Firestore.
  /// Throws [FirebaseException] if the add operation fails.
  Future<void> addOrganisation(Organisation organisation) async {
    await organisationsRef.add(organisation);
  }

  /// Fetches an organisation by its organisationId field from Firestore.
  ///
  /// Parameters:
  /// - [organisationId]: The organisationId field value to search for
  ///
  /// Returns the [Organisation] object if found.
  /// Throws [FirebaseException] if the fetch operation fails.
  /// Throws [Exception] if the organisation is not found.
  Future<Organisation> getOrganisation(String organisationId) async {
    try {
      final querySnapshot = await organisationsRef
          .where('organisationId', isEqualTo: organisationId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception(
            'Organisation not found with organisationId: $organisationId');
      }

      return querySnapshot.docs.first.data();
    } on FirebaseException catch (e) {
      print('Firestore error fetching organisation: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error fetching organisation: $e');
      rethrow;
    }
  }

  /// Saves a new event to Firestore.
  ///
  /// Throws [FirebaseException] if the save operation fails.
  /// TODO: Add user authentication check and link event to user.
  Future<void> saveEvent(Event event) async {
    try {
      //Check if user logged in
      await eventsRef.add(event.toJson());
      //Add event id to user document
    } on FirebaseException catch (e) {
      print('Firestore error: ${e.message}');
      rethrow; // still rethrow but now logged
    } catch (e) {
      print('Unknown error saving event: $e');
      rethrow;
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      //Check if user logged in
      final eventDocRef = eventsRef.doc(event.id);
      await eventDocRef.update(event.toJson());
      //Add event id to user document
    } on FirebaseException catch (e) {
      print('Firestore error: ${e.message}');
      rethrow; // still rethrow but now logged
    } catch (e) {
      print('Unknown error saving event: $e');
      rethrow;
    }
  }

  // Future<void> updateEventFields(String eventId, Map<String, dynamic> fields) {
  //   return eventsRef.doc(eventId).update(fields);
  // }

  void addUpdateEventFieldsToBatch(
      WriteBatch batch, Map<String, dynamic> fields, String eventId) {
    final docRef = eventsRef.doc(eventId);
    batch.update(docRef, fields);
  }

  Future<List<Event>> getAllEvents(String organisationId) async {
    // TODO after login implementation:
// - Check if the user is logged in
// - Retrieve all events assigned to the user
// - Fetch only the assigned events (Firestore rules will also apply)

    try {
      List<Event> events = [];
      final snapshot = await eventsRef
          .where('organisationId', isEqualTo: organisationId)
          .get();
      events = snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
      return events;
    } on FirebaseException catch (e) {
      print('Firestore error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error fetching events: $e');
      rethrow;
    }
  }

  Future<Event> getEventById(String eventId) async {
    // TODO after login implementation:
// - Check if the user is logged in
// - Retrieve all events assigned to the user
// - Fetch only the assigned events (Firestore rules will also apply)
    final docRef = eventsRef.doc(eventId);
    final snapshot =
        await retryFirestore(() => docRef.get(), operationName: 'getEventById');
    Event event;
    event = Event.fromFirestore(snapshot);
    print('Fetched event: ${event.toString()}');
    return event;
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await eventsRef.doc(eventId).delete();
    } on FirebaseException catch (e) {
      print('Firestore error: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error deleting event: $e');
      rethrow;
    }
  }

  Future<void> saveSetQuestions(
      List<EventQuestions> list, String eventId) async {
    final data = list.map((e) => e.toJson()).toList();

    try {
      await eventsRef
          .doc(eventId)
          .collection('guestQuestions')
          .doc('config')
          .set({
        "guestQuestions": data,
      });
      print('Guest questions saved successfully.');
    } catch (error) {
      print('Failed to save guest questions: $error');
      rethrow; // Re-throw if you want the error to propagate
    }
  }

  Future<List<EventQuestions>> fetchAllSetQuestions(
    String eventId,
  ) async {
    print('Fetching guest questions from: $eventId');
    try {
      final snapshot = await eventsRef
          .doc(eventId)
          .collection('guestQuestions')
          .doc('config')
          .get();
      final data = snapshot.data();
      print(data);
      if (data != null && data.containsKey('guestQuestions')) {
        final List<dynamic> fieldsData = data['guestQuestions'];
        return fieldsData.map((field) {
          return EventQuestions(
              fieldName: field['fieldName'],
              groupId: field['groupId'],
              inputType: InputType.values.firstWhere(
                (e) => e.toString() == 'InputType.${field['inputType']}',
              ));
        }).toList();
      } else {
        throw Exception("No fields found");
      }
    } catch (e) {
      print('Fetch Started ${e.toString()}');
      throw Exception("Failed to fetch guest fields: $e");
    }
  }

  // Future<void> saveMenus(List<MenuItem> menus, String eventId) async {
  //   try {
  //     final menuData = menus.map((menu) => menu.toFirestore()).toList();
  //     await eventsRef.doc(eventId).collection('menus').doc('config').set({
  //       'menus': menuData,
  //     });
  //     print('Menus saved successfully.');
  //   } catch (error) {
  //     print('Failed to save menus: $error');
  //     rethrow;
  //   }
  // }

  void addMenusToBatch(
      WriteBatch batch, List<MenuItemOld> menus, String eventId) {
    final menuData = menus.map((menu) => menu.toFirestore()).toList();
    final docRef = eventsRef.doc(eventId).collection('menus').doc('config');

    batch.set(docRef, {'menus': menuData});
  }

  /// Fetches all menu items for a specific event.
  /// Returns an empty list if no menus are found.
  /// Returns a List of MenuItem objects if menus are found.
  /// If an error occurs, it throws an exception.
  Future<List<MenuItemOld>> getMenus(String eventId) async {
    try {
      final snapshot =
          await eventsRef.doc(eventId).collection('menus').doc('config').get();
      if (!snapshot.exists) {
        return [];
      }
      final data = snapshot.data();
      if (data != null && data.containsKey('menus')) {
        final List<dynamic> menusData = data['menus'];
        return menusData
            .map((menu) => MenuItemOld.fromFirestore(menu))
            .toList();
      } else {
        throw Exception("No menus found");
      }
    } catch (e) {
      print('Fetch Started ${e.toString()}');
      throw Exception("Failed to fetch menus: $e");
    }
  }

  ///Fetches all guests for a specific event.
  Future<List<Guest>> fetchGuests(String eventId) async {
    final colRef = eventsRef.doc(eventId).collection('guests');
    final snapshot = await retryFirestore(() => colRef.get());
    final guests =
        snapshot.docs.map((e) => Guest.fromFirestore(e.data(), e.id)).toList();
    return guests;
  }

  Future<Guest> fetchGuestById(String guestId, String eventId) async {
    //Implement retry
    final snapshot =
        await eventsRef.doc(eventId).collection('guests').doc(guestId).get();
    if (snapshot.exists) {
      final data = snapshot.data();
      final Guest guest = Guest.fromFirestore(data!, snapshot.id);
      return guest;
    }
    throw Exception('');
  }

  // Future<void> saveGuests(String eventId, List<Guest> guests) async {
  //   final batch = _db.batch();
  //   try {
  //     for (Guest element in guests) {
  //       final docRef = eventsRef.doc(eventId).collection('guests').doc();
  //       batch.set(docRef, element.toFirestore());
  //     }
  //     await batch.commit();
  //     print('Guests Saved Successfully');
  //   } catch (e) {
  //     print('Failed to save guests: $e');
  //     rethrow;
  //   }
  // }

  /// Saves a single guest to a specific event's guest collection in Firestore.
  ///
  /// Parameters:
  /// - [eventId]: The ID of the event to which the guest will be added
  /// - [guest]: The [Guest] object containing the guest's information
  ///
  /// Returns a [Future<String>] containing the newly created guest document ID.
  ///
  /// The method creates a new document in the guests subcollection with a
  /// auto-generated ID. Uses [SetOptions(merge: true)] to safely update existing
  /// guests without overwriting unspecified fields.
  ///
  /// Throws an exception if the save operation fails.
  Future<String> saveGuest(String eventId, Guest guest) async {
    try {
      final docRef = eventsRef.doc(eventId).collection('guests').doc();
      await docRef.set(guest.toFirestore(), SetOptions(merge: true));
      print('Guest Saved Successfully');
      return docRef.id;
    } catch (e) {
      print('Failed to save guest: $e');
      rethrow;
    }
  }

  Future<void> saveGuestList(String eventId, List<Guest> guests) async {
    final colRef = eventsRef.doc(eventId).collection('guests');
    final batch = _db.batch();
    for (var guest in guests) {
      colRef.doc().set(guest.toFirestore(), SetOptions(merge: true));
    }
    batch.commit();
  }

  /// Updates an existing guest in an event's guest collection in Firestore.
  ///
  /// Parameters:
  /// - [eventId]: The ID of the event containing the guest
  /// - [guest]: The [Guest] object with updated information. Must contain valid [id] field
  ///
  /// Returns a [Future<void>] that completes when the update is successful.
  ///
  /// The method updates the guest document in the guests subcollection using the guest's ID.
  /// Uses [SetOptions(merge: true)] to safely update only the specified fields.
  ///
  /// Throws an exception if the update operation fails.
  Future<void> updateGuest(String eventId, Guest guest) async {
    if (guest.id.isEmpty) {
      throw Exception('Guest ID cannot be empty for update operation');
    }

    try {
      final docRef = eventsRef.doc(eventId).collection('guests').doc(guest.id);
      await docRef.set(guest.toFirestore(), SetOptions(merge: true));
      print('Guest Updated Successfully');
    } catch (e) {
      print('Failed to update guest: $e');
      rethrow;
    }
  }

  /// Deletes a specific guest from an event's guest collection in Firestore.
  ///
  /// Parameters:
  /// - [eventId]: The ID of the event from which the guest will be removed
  /// - [guest]: The [Guest] object to be deleted. Must contain valid [id] field
  ///
  /// Returns a [Future<void>] that completes when the deletion is successful.
  ///
  /// The method removes the guest document from the guests subcollection
  /// using the guest's ID. If the guest doesn't exist, Firestore will still
  /// consider the operation successful.
  ///
  /// Throws an exception if the delete operation fails for other reasons.
  Future<void> deleteGuest(String eventId, Guest guest) async {
    try {
      final docRef = eventsRef.doc(eventId).collection('guests').doc(guest.id);
      await docRef.delete();
      print('Guest Deleted Successfully');
    } catch (e) {
      print('Failed to delete guest: $e');
      rethrow;
    }
  }

  Future<void> deleteAllGuests(String eventId) async {
    try {
      final colRef = eventsRef.doc(eventId).collection('guests');
      final snapshot = await colRef.get();
      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      print('All Guests Deleted Successfully');
    } catch (e) {
      print('Failed to delete all guests: $e');
      rethrow;
    }
  }

  Future<void> inviteGuest(String eventId, Guest guest) async {
    try {
      final querySnapshot =
          await usersRef.where('email', isEqualTo: guest.email).limit(1).get();
      final docRef = querySnapshot.docs.isNotEmpty
          ? querySnapshot.docs.first.reference
          : usersRef.doc();

      await docRef.set({
        'email': guest.email,
        'guest': FieldValue.arrayUnion([eventId])
      }, SetOptions(merge: true));

      print('Guest Invited Successfully');
    } catch (e) {
      print('Failed to invite guest: $e');
      rethrow;
    }
  }

  /// Saves multiple guest responses to a specific event in Firestore using batch write,
  /// replacing any existing responses.
  ///
  /// Parameters:
  /// - [eventId]: The ID of the event to which the responses belong
  /// - [responses]: A list of [GuestResponse] objects containing guests' responses to event questions
  ///
  /// This method performs the following operations atomically in a batch:
  /// 1. Deletes all existing responses in the 'guestResponses' subcollection
  /// 2. Creates new documents for each response with auto-generated IDs
  ///
  /// The batch operation ensures that either all operations succeed or none do,
  /// maintaining data consistency. This is particularly important when replacing
  /// existing responses to avoid partial updates.
  ///
  /// Throws an exception if:
  /// - The batch commit operation fails
  /// - There are errors accessing the guestResponses collection
  /// - The operation exceeds Firestore batch size limits
  Future<void> saveGuestResponses(
      String eventId, List<GuestResponse> responses) async {
    final batch = FirebaseFirestore.instance.batch();

    final existingDocs =
        await eventsRef.doc(eventId).collection('guestResponses').get();
    for (final doc in existingDocs.docs) {
      batch.delete(doc.reference);
    }

    for (var response in responses) {
      final docRef = eventsRef.doc(eventId).collection('guestResponses').doc();
      batch.set(docRef, response.toFirestore());
    }
    await batch.commit();
  }

  /// Fetches responses for a guest from an event, including both direct responses and invited guest responses.
  /// Uses a compound query to find responses where the guest is either the respondent or the inviter.
  ///
  /// Parameters:
  /// - [eventId]: ID of the event to fetch responses from
  /// - [guestId]: ID of the guest whose responses to fetch (as respondent or inviter)
  ///
  /// Returns a list of [GuestResponse] objects. Throws an exception if no responses are found.
  Future<List<GuestResponse>> fetchGuestResponses(
      String eventId, String guestId) async {
    // final docRef =await  eventsRef.doc(eventId).collection('guestResponses').where('guestId', isEqualTo: guestId );
    final docRef = eventsRef.doc(eventId).collection('guestResponses').where(
        Filter.or(Filter('guestId', isEqualTo: guestId),
            Filter('inviterId', isEqualTo: guestId)));
    // where('guestId', isEqualTo: guestId );
    final snapshot = await retryFirestore(() => docRef.get(),
        operationName: 'Fetching guest responses');
    if (snapshot.docs.isNotEmpty) {
      final responses = snapshot.docs
          .map((e) => GuestResponse.fromFirestore(e.data()))
          .toList();
      return responses;
    }

    return [];
  }

  Future<List<GuestResponse>> fetchAllGuestResponses(String eventId) async {
    final docRef = eventsRef.doc(eventId).collection('guestResponses');
    final snapshot = await retryFirestore(() => docRef.get(),
        operationName: 'Fetching guest responses');
    if (snapshot.docs.isNotEmpty) {
      final responses = snapshot.docs
          .map((e) => GuestResponse.fromFirestore(e.data()))
          .toList();
      return responses;
    }

    return [];
  }

  Future<void> saveMenusAndUpdateEventFields(
    String eventId,
    List<MenuItemOld> menus,
    Map<String, dynamic> fields,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      addMenusToBatch(batch, menus, eventId);
      addUpdateEventFieldsToBatch(batch, fields, eventId);
      await batch.commit();
      print('Batch commit successful!');
    } catch (error) {
      print('Failed to commit batch: $error');
      rethrow;
    }
  }

  // VENUE SERVICES

  /// Creates a new venue in Firestore.
  ///
  /// Parameters:
  /// - [venue]: The venue object to create
  ///
  /// Returns the document ID of the created venue.
  /// Throws [FirebaseException] if the create operation fails.
  Future<String> createVenue(Venue venue) async {
    try {
      // Ensure venueID is set (UUID4)
      final uuid = Uuid();
      final venueWithId = venue.copyWith(venueID: uuid.v4());

      // Use add with explicit create data to ensure proper timestamps
      final docRef =
          await _db.collection(venuesCol).add(venueWithId.toFirestoreCreate());
      print('Venue created successfully with ID: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      print('Firestore error creating venue: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error creating venue: $e');
      rethrow;
    }
  }

  /// Fetches all venues for a specific organisation from Firestore.
  ///
  /// Parameters:
  /// - [organisationId]: The organisation ID to filter venues by
  ///
  /// Returns a list of [Venue] objects for the organisation.
  /// Returns empty list if no venues are found.
  /// Throws [FirebaseException] if the fetch operation fails.
  Future<List<Venue>> getVenues(String organisationId) async {
    try {
      final querySnapshot = await retryFirestore(
        () => venuesRef
            .where('organisationId', isEqualTo: organisationId)
            .where('isDisabled', isEqualTo: false)
            .orderBy('name')
            .get(),
        operationName: 'Fetching venues for organisation',
      );

      if (querySnapshot.docs.isEmpty) {
        print('No venues found for organisation: $organisationId');
        return [];
      }

      final venues = querySnapshot.docs.map((doc) => doc.data()).toList();
      print('Found ${venues.length} venues for organisation: $organisationId');
      return venues;
    } on FirebaseException catch (e) {
      print('Firestore error fetching venues: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error fetching venues: $e');
      rethrow;
    }
  }

  /// Updates an existing venue in Firestore.
  ///
  /// Parameters:
  /// - [venue]: The venue object with updated data
  ///
  /// Throws [FirebaseException] if the update operation fails.
  /// Throws [Exception] if venue ID is null.
  Future<void> updateVenue(Venue venue) async {
    if (venue.venueID == null) {
      throw Exception('Cannot update venue: venue ID is null');
    }

    try {
      await venuesRef.doc(venue.venueID).update(venue.toFirestoreUpdate());
      print('Venue updated successfully: ${venue.venueID}');
    } on FirebaseException catch (e) {
      print('Firestore error updating venue: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error updating venue: $e');
      rethrow;
    }
  }

  /// Soft deletes a venue by setting isDisabled to true.
  ///
  /// Parameters:
  /// - [venueId]: The ID of the venue to disable
  ///
  /// Throws [FirebaseException] if the delete operation fails.
  Future<void> deleteVenue(String venueId) async {
    try {
      await venuesRef.doc(venueId).update({
        'isDisabled': true,
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      print('Venue soft deleted successfully: $venueId');
    } on FirebaseException catch (e) {
      print('Firestore error deleting venue: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error deleting venue: $e');
      rethrow;
    }
  }

  /// Fetches a single venue by its ID.
  ///
  /// Parameters:
  /// - [venueId]: The ID of the venue to fetch
  ///
  /// Returns the [Venue] object if found.
  /// Throws [FirebaseException] if the fetch operation fails.
  /// Throws [Exception] if the venue is not found.
  Future<Venue> getVenueById(String venueId) async {
    try {
      final docSnapshot = await retryFirestore(
        () => venuesRef.doc(venueId).get(),
        operationName: 'Fetching venue by ID',
      );

      if (!docSnapshot.exists) {
        throw Exception('Venue not found with ID: $venueId');
      }

      final venue = docSnapshot.data();
      if (venue == null) {
        throw Exception('Venue data is null for ID: $venueId');
      }

      print('Venue fetched successfully: $venueId');
      return venue;
    } on FirebaseException catch (e) {
      print('Firestore error fetching venue: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error fetching venue: $e');
      rethrow;
    }
  }

  Future<MenuItem> createMenuItem(MenuItem menuItem) async {
    final uuid = Uuid();
    final menuItemId = uuid.v4();
    final item = menuItem.copyWith(menuItemId: menuItemId);
    final result = await menuItemsRef.add(item.toFirestoreCreate());
    return item;
  }

  Future<List<new_menu.MenuItem>> getAllMenus(String organisationId) async {
    final query =
        await menuItemsRef.where('venuID', isEqualTo: organisationId).get();
    return query.docs
        .map((doc) => new_menu.MenuItem.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateMenuItem(new_menu.MenuItem menuItem) async {
    if (menuItem.menuItemId == null)
      throw Exception('menuItemId required for update');
    await menuItemsRef
        .doc(menuItem.menuItemId)
        .update(menuItem.toFirestoreUpdate());
  }

  Future<void> deleteMenuItem(String menuItemId) async {
    await menuItemsRef.doc(menuItemId).delete();
  }
}
