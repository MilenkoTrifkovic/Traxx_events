import 'package:firebase_auth/firebase_auth.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/helper/firestore_helper.dart';
import 'package:traxx_wepapp/models/guest_dart.dart';
import 'package:traxx_wepapp/models/event_questions.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/guest_response.dart';
import 'package:traxx_wepapp/models/menu_old.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/utils/collect_ref.dart';
import 'package:traxx_wepapp/utils/enums/input_type.dart';
// import 'package:traxx_wepapp/models/menu_item.dart' as new_menu;
import 'package:traxx_wepapp/models/menu_item.dart';

class FirestoreServices {
  final _db = FirebaseFirestore.instance;

  /// Reference to users collection in Firestore
  late final CollectionReference<Map<String, dynamic>> usersRef;

  /// Reference to events collection in Firestore
  late final CollectionReference<Map<String, dynamic>> eventsRef;

  /// Reference to events collection in Firestore
  late final CollectionReference<Map<String, dynamic>> guestsRef;

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
    guestsRef = _db.collection(guestsCol);
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
      // 1️⃣ First, try direct doc lookup using organisationId as the doc id
      final byDoc = await organisationsRef.doc(organisationId).get();
      if (byDoc.exists) {
        return byDoc.data()!; // Organisation from doc id
      }

      // 2️⃣ Fallback: legacy path, search by organisationId field
      final querySnapshot = await organisationsRef
          .where('organisationId', isEqualTo: organisationId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception(
          'Organisation not found with organisationId: $organisationId',
        );
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

  /// Updates an existing organisation in Firestore.
  ///
  /// Validates that [organisation.organisationId] is provided, tries a direct
  /// document lookup first (using the organisationId as the doc id), falls
  /// back to querying by the 'organisationId' field, preserves the original
  /// createdAt timestamp if present, and updates the document with the
  /// provided organisation data.
  Future<Organisation> updateOrganisation(Organisation organisation) async {
    try {
      if (organisation.organisationId == null ||
          organisation.organisationId!.isEmpty) {
        throw Exception('organisationId is required for update');
      }

      // Try direct doc lookup by organisationId (doc id)
      final docRef = organisationsRef.doc(organisation.organisationId);
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        final existing = docSnap.data();
        final updateData = organisation.toJson();

        // Preserve createdAt if present on existing document
        if (existing?.createdAt != null) {
          // updateData['createdAt'] = existing!.createdAt?.toIso8601String();
          updateData['createdAt'] = existing!.createdAt;
        }

        // Set modifiedDate to current server timestamp
        updateData['modifiedDate'] = FieldValue.serverTimestamp();

        await docRef.update(updateData);
        return organisation;
      }

      // Fallback: legacy documents where organisationId is stored as a field
      final querySnapshot = await organisationsRef
          .where('organisationId', isEqualTo: organisation.organisationId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Organisation not found');
      }

      final ref = querySnapshot.docs.first.reference;
      final existing = querySnapshot.docs.first.data();
      final updateData = organisation.toJson();
      if (existing.createdAt != null) {
        // updateData['createdAt'] = existing.createdAt?.toIso8601String();
        updateData['createdAt'] = existing!.createdAt;
      }

      // Set modifiedDate to current server timestamp
      updateData['modifiedDate'] = FieldValue.serverTimestamp();
      // updateData['modifiedDate'] = DateTime.now().toIso8601String();

      await ref.update(updateData);
      return organisation;
    } on FirebaseException catch (e) {
      print('Firestore error updating organisation: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error updating organisation: $e');
      rethrow;
    }
  }

  /// Saves a new event to Firestore.
  ///
  /// Throws [FirebaseException] if the save operation fails.
  /// TODO: Add user authentication check and link event to user.
  Future<Event> saveEvent(Event event) async {
    try {
      // Assign a new UUID v4 to eventId if not provided
      final uuid = Uuid();
      final id = event.eventId ?? uuid.v4();
      final eventWithId = event.copyWith(eventId: id);

      // Convert to map and remove nulls (but do NOT rely on client-side timestamps)
  final data = Map<String, dynamic>.from(eventWithId.toJson());
      data.removeWhere((k, v) => v == null);

      // Ensure server-side timestamps for createdAt and updatedAt
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Persist using the eventId as document id so callers can rely on it
      await eventsRef.doc(id).set(data);

      return eventWithId;
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
      // Query for the document where eventId == event.eventId
      final querySnapshot = await eventsRef
          .where('eventId', isEqualTo: event.eventId)
          .limit(1)
          .get();
      if (querySnapshot.docs.isEmpty) {
        throw Exception('No event found with eventId: ${event.eventId}');
      }
      final eventDocRef = querySnapshot.docs.first.reference;
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
  Future<List<Guest_old>> fetchGuestsOld(String eventId) async {
    final colRef = eventsRef.doc(eventId).collection('guests');
    final snapshot = await retryFirestore(() => colRef.get());
    final guests = snapshot.docs
        .map((e) => Guest_old.fromFirestore(e.data(), e.id))
        .toList();
    return guests;
  }

  Future<List<GuestModel>> fetchGuests(String eventId) async {
    // final colRef = eventsRef.doc(eventId).collection('guests');
    final snapshot = await retryFirestore(() => guestsRef
        .where('eventId', isEqualTo: eventId)
        .where('isDisabled', isEqualTo: false)
        .get());
    final guests = snapshot.docs
        .map((e) => GuestModel.fromFirestore(e.data(), e.id))
        .toList();
    return guests;
  }

  Future<Guest_old> fetchGuestById(String guestId, String eventId) async {
    //Implement retry
    final snapshot =
        await eventsRef.doc(eventId).collection('guests').doc(guestId).get();
    if (snapshot.exists) {
      final data = snapshot.data();
      final Guest_old guest = Guest_old.fromFirestore(data!, snapshot.id);
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
  /// - [guest]: The [Guest_old] object containing the guest's information
  ///
  /// Returns a [Future<String>] containing the newly created guest document ID.
  ///
  /// The method creates a new document in the guests subcollection with a
  /// auto-generated ID. Uses [SetOptions(merge: true)] to safely update existing
  /// guests without overwriting unspecified fields.
  ///
  /// Throws an exception if the save operation fails.
  Future<GuestModel> saveGuest(GuestModel guest) async {
    try {
      final userFieldId = (guest.guestId != null && guest.guestId!.isNotEmpty)
          ? guest.guestId!
          : const Uuid().v4();

      final toSave = guest.copyWith(guestId: userFieldId);

      // Use userFieldId as Firestore document ID also
      final docRef = guestsRef.doc(userFieldId);

      await docRef.set(toSave.toFirestoreCreate());

      print('Guest Saved Successfully');
      return toSave;
    } catch (e) {
      print('Failed to save guest: $e');
      rethrow;
    }
  }

  /// Deletes a guest from Firestore by guest ID.
  ///
  /// This method searches for a guest by their guestId field and deletes the document.
  ///
  /// @param guestId The ID of the guest to delete
  /// @throws Exception if guest is not found
  /// @throws Exception if Firestore operation fails
  Future<void> deleteGuest(String guestId) async {
    try {
      // Search for the document where the 'guestId' field matches the provided ID
      final querySnapshot = await guestsRef
          .where('guestId', isEqualTo: guestId)
          .limit(1) // We only expect one document with this guestId
          .get();

      // Check if guest exists
      if (querySnapshot.docs.isEmpty) {
        throw Exception('Guest with ID $guestId not found');
      }

      // Get the document reference from the query result
      final docRef = querySnapshot.docs.first.reference;

      // Delete the document from Firestore
      await docRef.delete();

      print('Guest with ID $guestId deleted successfully');
    } catch (e) {
      print('Failed to delete guest with ID $guestId: $e');
      rethrow; // Re-throw the exception for handling in the calling code
    }
  }

  /// Updates an existing guest in Firestore.
  ///
  /// This method finds a guest by guestId, updates the provided fields,
  /// and preserves the original createdAt timestamp while updating modifiedAt.
  ///
  /// @param updatedGuest The GuestModel object with updated values
  /// @throws Exception if guest is not found
  /// @throws Exception if Firestore operation fails
  /// @returns The updated GuestModel
  Future<GuestModel> updateGuest(GuestModel updatedGuest) async {
    try {
      // Validate that guestId is provided
      if (updatedGuest.guestId == null || updatedGuest.guestId!.isEmpty) {
        throw Exception('Guest ID is required for update');
      }

      // Search for the document with the matching guestId field
      final querySnapshot = await guestsRef
          .where('guestId', isEqualTo: updatedGuest.guestId)
          .limit(1)
          .get();

      // Check if guest exists
      if (querySnapshot.docs.isEmpty) {
        throw Exception('Guest with ID ${updatedGuest.guestId} not found');
      }

      // Get the document reference and existing data
      final docRef = querySnapshot.docs.first.reference;
      final existingData = querySnapshot.docs.first.data();

      // Get the original createdAt timestamp from existing data
      final originalCreatedAt = existingData['createdAt'];

      // Prepare update data using toFirestoreUpdate()
      final updateData = updatedGuest.toFirestoreUpdate();

      // Ensure createdAt is not overwritten - preserve original value
      if (originalCreatedAt != null) {
        updateData['createdAt'] = originalCreatedAt;
      }

      // Update the document in Firestore
      await docRef.update(updateData);

      print('Guest with ID ${updatedGuest.guestId} updated successfully');

      // Return the updated guest model
      return updatedGuest;
    } catch (e) {
      print('Failed to update guest with ID ${updatedGuest.guestId}: $e');
      rethrow;
    }
  }

  Future<String> saveGuestOld(String eventId, Guest_old guest) async {
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

  Future<void> saveGuestList(String eventId, List<Guest_old> guests) async {
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
  /// - [guest]: The [Guest_old] object with updated information. Must contain valid [id] field
  ///
  /// Returns a [Future<void>] that completes when the update is successful.
  ///
  /// The method updates the guest document in the guests subcollection using the guest's ID.
  /// Uses [SetOptions(merge: true)] to safely update only the specified fields.
  ///
  /// Throws an exception if the update operation fails.
  Future<void> updateGuestOld(String eventId, Guest_old guest) async {
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
  /// - [guest]: The [Guest_old] object to be deleted. Must contain valid [id] field
  ///
  /// Returns a [Future<void>] that completes when the deletion is successful.
  ///
  /// The method removes the guest document from the guests subcollection
  /// using the guest's ID. If the guest doesn't exist, Firestore will still
  /// consider the operation successful.
  ///
  /// Throws an exception if the delete operation fails for other reasons.
  Future<void> deleteGuestOld(String eventId, Guest_old guest) async {
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

  Future<void> inviteGuest(String eventId, Guest_old guest) async {
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
  ///
  Future<String> createVenue(Venue venue) async {
    try {
      // Ensure venueID is set (UUID4)
      final uuid = Uuid();
      final venueWithId = venue.copyWith(venueID: uuid.v4());

      // Build the data map
      final Map<String, dynamic> data = venueWithId.toFirestoreCreate();

      // 🔐 IMPORTANT: ensure organisationId is present for security rules
      // (even if toFirestoreCreate already adds it, this is safe and explicit)
      data['organisationId'] = venueWithId.organisationId;

      // Use add with explicit create data to ensure proper timestamps
      final docRef = await _db.collection(venuesCol).add(data);
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
  /* Future<String> createVenue(Venue venue) async {
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
  } */

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
  /// Finds the venue by venueID and updates it with the provided data.
  /// Preserves the original createdAt timestamp and updates modifiedAt.
  ///
  /// @param venue The updated Venue object with venueID
  /// @throws FirebaseException if Firestore operation fails
  /// @throws Exception if venueID is missing
  /// @returns The updated Venue
  Future<Venue> updateVenue(Venue venue) async {
    try {
      // Validate that venueID is provided
      if (venue.venueID == null || venue.venueID!.isEmpty) {
        throw Exception('venueID is required for update');
      }

      // Build the update data map using toFirestoreUpdate()
      final Map<String, dynamic> updateData = venue.toFirestoreUpdate();

      // Ensure organisationId is present (security rules requirement)
      updateData['organisationId'] = venue.organisationId;

      // Find the document by venueID field
      final querySnapshot = await _db
          .collection(venuesCol)
          .where('venueID', isEqualTo: venue.venueID)
          .limit(1)
          .get();

      // Check if venue exists
      if (querySnapshot.docs.isEmpty) {
        throw Exception('Venue with ID ${venue.venueID} not found');
      }

      // Get the document reference
      final docRef = querySnapshot.docs.first.reference;

      // Get existing data to preserve createdAt
      final existingData = querySnapshot.docs.first.data();
      final originalCreatedAt = existingData['createdAt'];

      // Ensure createdAt is not overwritten (preserve original)
      if (originalCreatedAt != null) {
        updateData['createdAt'] = originalCreatedAt;
      } else {
        // If createdAt doesn't exist in old document, add it from the venue object
        updateData['createdAt'] =
            venue.createdAt ?? FieldValue.serverTimestamp();
      }

      // Perform the update
      await docRef.update(updateData);

      print('Venue with ID ${venue.venueID} updated successfully');

      // Return the venue with updated timestamps if needed
      return venue;
    } on FirebaseException catch (e) {
      print('Firestore error updating venue: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error updating venue: $e');
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
  // Future<void> updateVenue(Venue venue) async {
  //   if (venue.venueID == null) {
  //     throw Exception('Cannot update venue: venue ID is null');
  //   }

  //   try {
  //     await venuesRef.doc(venue.venueID).update(venue.toFirestoreUpdate());
  //     print('Venue updated successfully: ${venue.venueID}');
  //   } on FirebaseException catch (e) {
  //     print('Firestore error updating venue: ${e.message}');
  //     rethrow;
  //   } catch (e) {
  //     print('Unknown error updating venue: $e');
  //     rethrow;
  //   }
  // }

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
  await menuItemsRef.add(item.toFirestoreCreate());

  return item;
  }

  Future<List<MenuItem>> getAllMenus(String organisationId) async {
    final query = await menuItemsRef
        .where('organisationId', isEqualTo: organisationId)
        .get();
    print('menu items fetched: ${query.docs.length}');
    return query.docs
        .map((doc) => MenuItem.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateMenuItem(MenuItem menuItem) async {
    if (menuItem.menuItemId == null)
      throw Exception('menuItemId required for update');
    await menuItemsRef
        .doc(menuItem.menuItemId)
        .update(menuItem.toFirestoreUpdate());
  }

  Future<void> deleteMenuItem(String menuItemId) async {
    await menuItemsRef.doc(menuItemId).delete();
  }

  Future<List<MenuItem>> getMenuItemsByVenueId(String venueId) async {
    final querySnapshot = await retryFirestore(
      () => menuItemsRef.where('venuID', isEqualTo: venueId).get(),
      operationName: 'Fetching menu items by venueID',
    );
    return querySnapshot.docs
        .map((doc) => MenuItem.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Save event using event.eventId as the Firestore document ID.
  /// If event.eventId is null, a UUIDv4 will be assigned and used as doc id.
  // Future<void> saveEvent(Event event) async {
  //   try {
  //     final uuid = Uuid();
  //     final id = event.eventId ?? uuid.v4();
  //     final e = event.copyWith(eventId: id);
  //     // Use doc(id).set so that eventsRef.doc(id) will exist later
  //     await eventsRef.doc(id).set(e.toJson());
  //     print('Event saved with document id: $id');
  //   } on FirebaseException catch (e) {
  //     print('Firestore error saving event: ${e.message}');
  //     rethrow;
  //   } catch (e) {
  //     print('Unknown error saving event: $e');
  //     rethrow;
  //   }
  // }

  // /// Update event by using the document id == event.eventId.
  // /// Throws if event.eventId is null or doc does not exist.
  // Future<void> updateEvent(Event event) async {
  //   if (event.eventId == null || event.eventId!.isEmpty) {
  //     throw Exception('eventId missing on event');
  //   }

  //   final docRef = eventsRef.doc(event.eventId);
  //   final snapshot = await docRef.get();
  //   if (!snapshot.exists) {
  //     throw Exception('No event found with id: ${event.eventId}');
  //   }
  //   try {
  //     await docRef.update(event.toJson());
  //   } on FirebaseException catch (e) {
  //     print('Firestore error updating event: ${e.message}');
  //     rethrow;
  //   } catch (e) {
  //     print('Unknown error updating event: $e');
  //     rethrow;
  //   }
  // }

  // /// Get event document by document id (eventId).
  // Future<Event> getEventById(String eventId) async {
  //   try {
  //     final docRef = eventsRef.doc(eventId);
  //     final snapshot = await docRef.get();
  //     if (!snapshot.exists) {
  //       throw Exception('Event not found for id: $eventId');
  //     }
  //     return Event.fromFirestore(snapshot);
  //   } on FirebaseException catch (e) {
  //     print('Firestore error: ${e.message}');
  //     rethrow;
  //   } catch (e) {
  //     print('Unknown error: $e');
  //     rethrow;
  //   }
  // }

  /// Update only the given fields on the event document (atomic).
  Future<void> updateEventFields(
      String eventId, Map<String, dynamic> fields) async {
    final docRef = eventsRef.doc(eventId);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('No event found with id: $eventId');
    }
    fields['updatedAt'] = FieldValue.serverTimestamp();
    await docRef.update(fields);
  }

  // --------------------------
  // Responses (audit/history) helper
  // --------------------------

  /// Write an audit/response doc under events/{eventId}/responses.
  /// Call this whenever the user chooses a menu, adds / removes items, or selects demographic set.
  Future<void> writeResponseAudit(
      String eventId, Map<String, dynamic> payload) async {
    if (eventId.isEmpty) return;
    final actor = FirebaseAuth.instance.currentUser?.uid;
    payload['actorUserId'] = actor;
    payload['createdAt'] = FieldValue.serverTimestamp();
    final ref = eventsRef.doc(eventId).collection('responses').doc();
    await ref.set(payload);
  }

  // --------------------------
  // Existing methods kept (menus, guests, guestResponses, etc.)
  // Adjusted only where they touched eventsRef.doc(eventId)
  // --------------------------

  // Future<void> saveSetQuestions(
  //     List<EventQuestions> list, String eventId) async {
  //   final data = list.map((e) => e.toJson()).toList();
  //   try {
  //     await eventsRef
  //         .doc(eventId)
  //         .collection('guestQuestions')
  //         .doc('config')
  //         .set({
  //       "guestQuestions": data,
  //     });
  //     print('Guest questions saved successfully.');
  //   } catch (e) {
  //     print('Failed to save guest questions: $e');
  //     rethrow;
  //   }
  // }

  // Future<List<EventQuestions>> fetchAllSetQuestions(String eventId) async {
  //   try {
  //     final snapshot = await eventsRef
  //         .doc(eventId)
  //         .collection('guestQuestions')
  //         .doc('config')
  //         .get();
  //     final data = snapshot.data();
  //     if (data != null && data.containsKey('guestQuestions')) {
  //       final List<dynamic> fieldsData = data['guestQuestions'];
  //       return fieldsData.map((field) {
  //         return EventQuestions(
  //           fieldName: field['fieldName'],
  //           groupId: field['groupId'],
  //           inputType: InputType.values.firstWhere(
  //             (e) => e.toString() == 'InputType.${field['inputType']}',
  //           ),
  //         );
  //       }).toList();
  //     } else {
  //       return [];
  //     }
  //   } catch (e) {
  //     print('Failed to fetch guest fields: $e');
  //     rethrow;
  //   }
  // }

  // // keep the rest of your methods unmodified (getMenus, saveGuest, etc.)
  // // but ensure they use eventsRef.doc(eventId) consistently

  // // Example: batch helper (keeps same semantics)
  // void addUpdateEventFieldsToBatch(
  //     WriteBatch batch, Map<String, dynamic> fields, String eventId) {
  //   final docRef = eventsRef.doc(eventId);
  //   batch.update(docRef, fields);
  // }

  // // Also keep getAllEvents and others but they will work as before
  // Future<List<Event>> getAllEvents(String organisationId) async {
  //   try {
  //     final snapshot = await eventsRef
  //         .where('organisationId', isEqualTo: organisationId)
  //         .get();
  //     return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
  //   } catch (e) {
  //     print('Error getAllEvents: $e');
  //     rethrow;
  //   }
  // }

  // Example of write wrapper used by UI if you prefer centralized update
  Future<void> chooseMenuForEvent(String eventId, String menuId) async {
    await updateEventFields(eventId, {
      'selectedMenuId': menuId,
      'selectedMenuItemIds': <String>[],
    });
    await writeResponseAudit(eventId, {
      'type': 'menu_selection',
      'selectedMenuId': menuId,
      'selectedMenuItemIds': <String>[]
    });
  }

  Future<void> addMenuItemToEvent(String eventId, String menuItemId,
      {String? menuId}) async {
    await eventsRef.doc(eventId).update({
      'selectedMenuItemIds': FieldValue.arrayUnion([menuItemId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await writeResponseAudit(eventId, {
      'type': 'menu_item_added',
      'menuItemId': menuItemId,
      if (menuId != null) 'menuId': menuId,
    });
  }

  Future<void> removeMenuItemFromEvent(String eventId, String menuItemId,
      {String? menuId}) async {
    await eventsRef.doc(eventId).update({
      'selectedMenuItemIds': FieldValue.arrayRemove([menuItemId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await writeResponseAudit(eventId, {
      'type': 'menu_item_removed',
      'menuItemId': menuItemId,
      if (menuId != null) 'menuId': menuId,
    });
  }

  Future<void> chooseDemographicSetForEvent(
      String eventId, String questionSetId) async {
    await updateEventFields(eventId, {
      'selectedDemographicQuestionSetId': questionSetId,
    });
    await writeResponseAudit(eventId, {
      'type': 'demographic_selection',
      'questionSetId': questionSetId,
    });
  }
}
