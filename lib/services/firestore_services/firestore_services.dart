import 'package:firebase_auth/firebase_auth.dart';
import 'package:traxx_wepapp/models/guest_model.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/models/sales_person_model.dart';
import 'package:traxx_wepapp/view/common/event_list_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/helper/firestore_helper.dart';
import 'package:traxx_wepapp/helper/invitation_code_generator.dart';
import 'package:traxx_wepapp/helper/batch_id_generator.dart';
import 'package:traxx_wepapp/models/guest_dart.dart';
import 'package:traxx_wepapp/models/event_questions.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/models/guest_response.dart';
import 'package:traxx_wepapp/models/menu_old.dart';
import 'package:traxx_wepapp/models/organisation.dart';
import 'package:traxx_wepapp/models/venue.dart';
import 'package:traxx_wepapp/utils/collect_ref.dart';
import 'package:traxx_wepapp/utils/enums/event_status.dart';
import 'package:traxx_wepapp/utils/enums/input_type.dart';

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

  /// Reference to sales_people collection in Firestore
  late final CollectionReference<Map<String, dynamic>> salesPeopleRef;

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
    salesPeopleRef = _db.collection('sales_people');
  }

  Future<Event> copyEventAsDraft(
    Event source, {
    required String organisationId,
    CopyEventOptions? options,
  }) async {
    final ref = _db.collection('events').doc();
    final newId = ref.id;

    final opts = options ??
        CopyEventOptions(
          newName: '${source.name} (Copy)',
          copyDemographics: true,
          copyMenuAndDishes: true,
          copyVenue: true,
          copyCoverImage: true,
        );

    final data = Map<String, dynamic>.from(source.toJson());

    // ✅ core fields always copied
    data['eventId'] = newId;
    data['organisationId'] = organisationId;
    data['name'] = opts.newName.trim().isEmpty
        ? '${source.name} (Copy)'
        : opts.newName.trim();
    data['status'] = EventStatus.draft.statusName;

    // ✅ timestamps should be server timestamps
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    // ✅ IMPORTANT: new unique invitation code (avoid duplicates)
    data['invitationCode'] = await _generateUniqueInvitationCode();

    // ✅ Do NOT carry invitation letter when copying (safe default)
    data.remove('invitationLetterPath');
    data.remove('invitationLetterUrl');

    // -------------------------
    // Apply copy options
    // -------------------------
    if (!opts.copyDemographics) {
      data.remove('selectedDemographicQuestionSetId');
    }

    if (!opts.copyMenuAndDishes) {
      data.remove('selectedMenuId');
      data.remove('selectedMenuItemIds');
      data.remove('selectedMenus');
      data.remove('menuItemGroups'); // if present in some docs
    }

    if (!opts.copyVenue) {
      // keep key but make empty so UI treats it as "not selected"
      data['venueId'] = '';
    }

    if (!opts.copyCoverImage) {
      data.remove('coverImageUrl');
      data.remove('coverImageDownloadUrl'); // if present in some docs
    }

    await ref.set(data);

    final snap = await ref.get();
    return Event.fromFirestore(snap);
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
        updateData['createdAt'] = existing.createdAt;
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

  /// Generates a unique invitation code that doesn't exist in Firestore.
  ///
  /// This method will keep generating new codes until it finds one that
  /// is not already used by any event. Maximum 10 attempts to prevent
  /// infinite loops in case of issues.
  ///
  /// Returns a unique invitation code in format: WE2390RT
  /// Throws [Exception] if unable to generate unique code after max attempts.
  Future<String> _generateUniqueInvitationCode() async {
    const maxAttempts = 10;
    int attempts = 0;

    while (attempts < maxAttempts) {
      final code = generateInvitationCode();

      // Check if this code already exists
      final existingEvents = await eventsRef
          .where('invitationCode', isEqualTo: code)
          .limit(1)
          .get();

      // If no events found with this code, it's unique!
      if (existingEvents.docs.isEmpty) {
        print('Generated unique invitation code: $code');
        return code;
      }

      print('Invitation code collision detected: $code. Generating new one...');
      attempts++;
    }

    throw Exception(
        'Failed to generate unique invitation code after $maxAttempts attempts');
  }

  /// Generates a unique batch ID that doesn't exist in Firestore.
  ///
  /// This method will keep generating new 6-digit batch IDs until it finds one
  /// that is not already used by any guest. Maximum 10 attempts to prevent
  /// infinite loops in case of issues.
  ///
  /// Returns a unique batch ID in format: 123456 (6 digits)
  /// Throws [Exception] if unable to generate unique batch ID after max attempts.
  Future<String> _generateUniqueBatchId() async {
    const maxAttempts = 10;
    int attempts = 0;

    while (attempts < maxAttempts) {
      final batchId = generateBatchId();

      // Check if this batch ID already exists
      final existingGuests =
          await guestsRef.where('batchId', isEqualTo: batchId).limit(1).get();

      // If no guests found with this batch ID, it's unique!
      if (existingGuests.docs.isEmpty) {
        print('Generated unique batch ID: $batchId');
        return batchId;
      }

      print('Batch ID collision detected: $batchId. Generating new one...');
      attempts++;
    }

    throw Exception(
        'Failed to generate unique batch ID after $maxAttempts attempts');
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

      // Generate unique invitation code if not provided
      final invitationCode =
          event.invitationCode ?? await _generateUniqueInvitationCode();

      final eventWithId = event.copyWith(
        eventId: id,
        invitationCode: invitationCode,
      );

      // Convert to map and remove nulls (but do NOT rely on client-side timestamps)
      final data = Map<String, dynamic>.from(eventWithId.toJson());
      // final data = Map<String, dynamic>.from(eventWithId.toJson());
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
    try {
      // 1) Try ordering by createdAt (recommended)
      final snapshot = await eventsRef
          .where('organisationId', isEqualTo: organisationId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      // 2) If createdAt is missing in some docs or index missing, fallback to no order
      // Common errors: failed-precondition (missing index) / invalid-argument
      print(
          'Firestore error fetching events (ordered): ${e.code} ${e.message}');
      try {
        final snapshot = await eventsRef
            .where('organisationId', isEqualTo: organisationId)
            .get();

        final events =
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();

        // Optional: local sort fallback if createdAt exists in model
        // If your Event model has createdAt DateTime? field, keep this.
        events.sort((a, b) {
          final aCreated =
              a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bCreated =
              b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bCreated.compareTo(aCreated);
        });

        return events;
      } catch (e2) {
        print('Fallback fetch events failed: $e2');
        rethrow;
      }
    } catch (e) {
      print('Unknown error fetching events: $e');
      rethrow;
    }
  }

  Future<DocumentReference<Map<String, dynamic>>> _eventRefByEventId(
      String eventId) async {
    final id = eventId.trim();

    final direct = eventsRef.doc(id);
    final snap = await direct.get();
    if (snap.exists) return direct;

    final q = await eventsRef.where('eventId', isEqualTo: id).limit(1).get();
    if (q.docs.isEmpty) {
      throw Exception('Event not found for eventId=$id');
    }
    return q.docs.first.reference;
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
      final id = eventId.trim();
      if (id.isEmpty) throw Exception('deleteEvent: eventId is empty');

      // ✅ Try docId == eventId (new schema)
      final directRef = eventsRef.doc(id);
      final directSnap = await directRef.get();

      if (directSnap.exists) {
        await directRef.delete();
        print('✅ Event deleted by docId: $id');
        return;
      }

      // ✅ Fallback: docId != eventId (old schema), delete by field match
      final q = await eventsRef.where('eventId', isEqualTo: id).limit(1).get();
      if (q.docs.isEmpty) {
        throw Exception('Event not found for eventId=$id');
      }

      await q.docs.first.reference.delete();
      print('✅ Event deleted by eventId field: $id');
    } on FirebaseException catch (e) {
      print('Firestore error deleting event: ${e.code} ${e.message}');
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

  Future<GuestModel> saveGuest(GuestModel guest) async {
    try {
      final userFieldId = (guest.guestId != null && guest.guestId!.isNotEmpty)
          ? guest.guestId!
          : const Uuid().v4();

      // Generate unique batch ID if not provided
      final batchId = guest.batchId ?? await _generateUniqueBatchId();

      final toSave = guest.copyWith(
        guestId: userFieldId,
        batchId: batchId,
      );

      // Use userFieldId as Firestore document ID also
      final docRef = guestsRef.doc(userFieldId);

      await docRef.set(toSave.toFirestoreCreate());

      print('Guest Saved Successfully with batch ID: $batchId');
      return toSave;
    } catch (e) {
      print('Failed to save guest: $e');
      rethrow;
    }
  }

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
      if (eventId.trim().isEmpty) {
        throw Exception('eventId is empty');
      }

      final email = (guest.email ?? '').trim();
      if (email.isEmpty) {
        throw Exception('guest.email is empty');
      }

      // ✅ IMPORTANT: do NOT query by email (email can be shared by multiple guests)
      // Use guest.id if you have it, otherwise create a new doc id.
      final docRef = (guest.id != null && guest.id!.trim().isNotEmpty)
          ? usersRef.doc(guest.id!.trim())
          : usersRef.doc();

      // (Optional) if guest didn't have an id, store it back locally
      guest.id ??= docRef.id;

      await docRef.set({
        'guestId': docRef.id,
        'email': email,
        if ((guest.name ?? '').trim().isNotEmpty) 'name': guest.name!.trim(),
        'eventIds': FieldValue.arrayUnion([eventId]),
        if (guest.companions != null) 'companions': guest.companions,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('Guest Invited Successfully (guestId=${docRef.id})');
    } catch (e) {
      print('Failed to invite guest: $e');
      rethrow;
    }
  }

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

  Future<String> createVenue(Venue venue) async {
    try {
      // Ensure venueID is set (UUID4)
      final uuid = Uuid();
      final venueId = uuid.v4();
      final venueWithId = venue.copyWith(venueID: venueId);

      // Build the data map
      final Map<String, dynamic> data = venueWithId.toFirestoreCreate();

      // 🔐 IMPORTANT: ensure organisationId is present for security rules
      // (even if toFirestoreCreate already adds it, this is safe and explicit)
      data['organisationId'] = venueWithId.organisationId;

      // Use add with explicit create data to ensure proper timestamps
      final docRef = await _db.collection(venuesCol).add(data);
      print(
          'Venue created successfully with docId: ${docRef.id}, venueID: $venueId');

      // Return the UUID venueID, NOT the Firestore document ID
      return venueId;
    } on FirebaseException catch (e) {
      print('Firestore error creating venue: ${e.message}');
      rethrow;
    } catch (e) {
      print('Unknown error creating venue: $e');
      rethrow;
    }
  }

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

  /// Fetches a single venue by its venueID field.
  ///
  /// Parameters:
  /// - [venueId]: The venueID field value to search for
  ///
  /// Returns the [Venue] object if found.
  /// Throws [FirebaseException] if the fetch operation fails.
  /// Throws [Exception] if the venue is not found.
  Future<Venue> getVenueById(String venueId) async {
    try {
      final querySnapshot = await retryFirestore(
        () => venuesRef.where('venueID', isEqualTo: venueId).limit(1).get(),
        operationName: 'Fetching venue by venueID field',
      );

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Venue not found with venueID: $venueId');
      }

      final venue = querySnapshot.docs.first.data();
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

  // SALES PERSON SERVICES

  /// Fetches a sales person by their refCode field.
  ///
  /// Parameters:
  /// - [refCode]: The reference code to search for (e.g., "MIL465")
  ///
  /// Returns the [SalesPersonModel] object if found, null otherwise.
  /// Throws [FirebaseException] if the fetch operation fails.
  Future<SalesPersonModel?> getSalesPersonByRefCode(String refCode) async {
    try {
      print('🔍 Searching for sales person with refCode: $refCode');

      final querySnapshot = await salesPeopleRef
          .where('refCode', isEqualTo: refCode.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('❌ No sales person found with refCode: $refCode');
        return null;
      }

      final doc = querySnapshot.docs.first;
      final salesPerson = SalesPersonModel.fromFirestore(doc.data(), doc.id);

      print('✅ Sales person found: ${salesPerson.name} (${salesPerson.docId})');
      return salesPerson;
    } on FirebaseException catch (e) {
      print('❌ Firebase error fetching sales person: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Unexpected error fetching sales person: $e');
      rethrow;
    }
  }

  // MENU SERVICES

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
    if (menuItem.menuItemId == null) {
      throw Exception('menuItemId required for update');
    }
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

  /// Update only the given fields on the event document (atomic).
  Future<void> updateEventFields(
      String eventId, Map<String, dynamic> fields) async {
    final ref = await _eventRefByEventId(eventId);
    fields['updatedAt'] = FieldValue.serverTimestamp();
    await ref.update(fields);
  }

  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    await updateEventFields(eventId, {
      'status': status.statusName, // ✅ use statusName (matches your schema)
    });
  }

  // --------------------------
  // Responses (audit/history) helper
  // --------------------------

  /// Write a guest response under events/{eventId}/guestResponses.
  /// Note: If you intended this to be an admin activity/audit log, consider
  /// keeping a separate 'activity' or 'audit' subcollection instead.
  Future<void> writeResponseAudit(
      String eventId, Map<String, dynamic> payload) async {
    if (eventId.isEmpty) return;
    final actor = FirebaseAuth.instance.currentUser?.uid;
    if (actor != null) payload['actorUserId'] = actor;
    payload['createdAt'] = FieldValue.serverTimestamp();

    final eventRef = await _eventRefByEventId(eventId);
    final ref = eventRef.collection('guestResponses').doc();
    await ref.set(payload);
  }

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
    final ref = await _eventRefByEventId(eventId);
    await ref.update({
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
    final ref = await _eventRefByEventId(eventId);
    await ref.update({
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

  // ---------------------------
  // Companion Guest Management
  // ---------------------------

  /// Creates companion guests with groupId and updates main guest atomically
  ///
  /// This method uses a Firestore batch write to ensure ALL operations succeed or fail together:
  /// 1. Generates a UUID v4 groupId
  /// 2. Updates the main guest document with the groupId
  /// 3. Creates all companion guest documents with the same groupId
  ///
  /// This guarantees data consistency - either all guests get the groupId or none do.
  ///
  /// Parameters:
  /// - [mainGuestId]: The main guest's guestId (from invitation) (required)
  /// - [companions]: List of GuestModel instances for companions (required)
  ///
  /// Returns:
  /// - Map with 'groupId' and 'createdGuestIds' list
  /// - Throws Exception if main guest not found
  /// - Throws FirebaseException on Firestore errors
  Future<Map<String, dynamic>> createCompanionsWithGroupId({
    required String mainGuestId,
    required List<GuestModel> companions,
  }) async {
    try {
      if (companions.isEmpty) {
        throw Exception('Companions list cannot be empty');
      }

      // Generate UUID v4 for groupId
      final uuid = Uuid();
      final groupId = uuid.v4();

      final batch = _db.batch();

      // Step 1: Find and update main guest document with groupId
      final mainGuestQuery = await guestsRef
          .where('guestId', isEqualTo: mainGuestId)
          .limit(1)
          .get();

      if (mainGuestQuery.docs.isEmpty) {
        throw Exception('Main guest with ID $mainGuestId not found');
      }

      final mainGuestRef = mainGuestQuery.docs.first.reference;
      batch.update(mainGuestRef, {
        'groupId': groupId,
        'modifiedAt': FieldValue.serverTimestamp(),
      });

      // Step 2: Create companion guest documents with groupId and batch ID
      // Use UUID v4 for guestId (not Firestore doc ID)
      final List<String> createdGuestIds = [];

      for (final companion in companions) {
        // Generate UUID v4 for guestId
        final guestId = uuid.v4();

        // Generate unique batch ID if not provided
        final batchId = companion.batchId ?? await _generateUniqueBatchId();

        // Create guest with groupId, batch ID, and UUID v4 guestId
        // Mark as companion since it's created through companion flow
        final guestWithId = companion.copyWith(
          docId: guestId, // Use guestId as docId too
          guestId: guestId, // UUID v4
          groupId: groupId,
          isCompanion: true, // Mark as companion
          batchId: batchId, // Unique batch ID
        );

        // Use guestId as document ID (following saveGuest pattern)
        final docRef = guestsRef.doc(guestId);

        // Add to batch
        batch.set(docRef, guestWithId.toFirestoreCreate());
        createdGuestIds.add(guestId);
      }

      // Step 3: Commit batch atomically
      await batch.commit();

      print(
          '✅ Created ${companions.length} companion(s) with groupId=$groupId');
      return {
        'groupId': groupId,
        'createdGuestIds': createdGuestIds,
      };
    } on FirebaseException catch (e) {
      print('❌ Firestore error creating companions with groupId: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error creating companions with groupId: $e');
      rethrow;
    }
  }

  /// Atomically creates a companion guest and links them to an invitation
  ///
  /// This method uses a Firestore batch write to ensure BOTH operations succeed or fail together:
  /// 1. Creates a new guest document in the 'guests' collection
  /// 2. Adds the companion entry to the invitation's 'companions' array
  ///
  /// This guarantees data consistency - you won't have orphaned guest records
  /// or invitations with missing companion references.
  ///
  /// Parameters:
  /// - [invitationId]: The invitation document ID to link the companion to (required)
  /// - [guest]: The GuestModel containing companion information (required)
  ///
  /// Returns:
  /// - The created guestId on success
  /// - Throws Exception if invitation not found
  /// - Throws Exception if duplicate email detected
  /// - Throws FirebaseException on Firestore errors
  Future<String> createCompanionAndLinkToInvitation({
    required String invitationId,
    required GuestModel guest,
  }) async {
    try {
      final batch = _db.batch();

      // Step 1: Get invitation to find main guest ID
      final invitationRef = _db.collection('invitations').doc(invitationId);
      final invitationDoc = await invitationRef.get();
      if (!invitationDoc.exists) {
        throw Exception('Invitation not found: $invitationId');
      }

      final invitationData = invitationDoc.data()!;
      final mainGuestId = (invitationData['guestId'] as String?) ?? '';

      if (mainGuestId.isEmpty) {
        throw Exception('Main guest ID not found in invitation');
      }

      // Step 2: Check/get groupId for main guest
      // If main guest doesn't have groupId, create one and assign it
      String groupId;
      final mainGuestQuery = await guestsRef
          .where('guestId', isEqualTo: mainGuestId)
          .limit(1)
          .get();

      if (mainGuestQuery.docs.isEmpty) {
        throw Exception('Main guest with ID $mainGuestId not found');
      }

      final mainGuestDoc = mainGuestQuery.docs.first;
      final mainGuestData = mainGuestDoc.data();
      final existingGroupId = mainGuestData['groupId'] as String?;

      if (existingGroupId != null && existingGroupId.isNotEmpty) {
        // Main guest already has a groupId, use it
        groupId = existingGroupId;
      } else {
        // Main guest doesn't have groupId, create one and assign it
        final uuid = Uuid();
        groupId = uuid.v4();
        batch.update(mainGuestDoc.reference, {
          'groupId': groupId,
          'modifiedAt': FieldValue.serverTimestamp(),
        });
      }

      // Step 3: Generate UUID v4 for companion guestId and batch ID
      final uuid = Uuid();
      final guestId = uuid.v4();

      // Generate unique batch ID if not provided
      final batchId = guest.batchId ?? await _generateUniqueBatchId();

      // Create guest with groupId, batch ID, isCompanion=true, and UUID v4 guestId
      final guestWithId = guest.copyWith(
        docId: guestId, // Use guestId as docId
        guestId: guestId, // UUID v4
        groupId: groupId,
        isCompanion: true, // Mark as companion
        batchId: batchId, // Unique batch ID
      );

      // Use guestId as document ID (following saveGuest pattern)
      final guestRef = guestsRef.doc(guestId);
      final guestData = guestWithId.toFirestoreCreate();

      // Add guest creation to batch
      batch.set(guestRef, guestData);

      // Step 4: Prepare invitation update
      final List<dynamic> existingCompanions =
          invitationData['companions'] as List<dynamic>? ?? [];

      // Check for duplicate email (prevent data inconsistency)
      final duplicateEmail = existingCompanions.any((companion) {
        final companionMap = companion as Map<String, dynamic>;
        return companionMap['guestEmail'] == guest.email;
      });

      if (duplicateEmail) {
        throw Exception(
            'A companion with email ${guest.email} already exists in this invitation');
      }

      // Create companion entry
      // Note: Cannot use FieldValue.serverTimestamp() inside arrayUnion()
      // Use DateTime.now() instead for the addedAt timestamp
      final companionEntry = {
        'guestId': guestId,
        'guestEmail': guest.email,
        'guestName': guest.name,
        'addedAt': Timestamp.now(),
      };

      // Add companion to invitation's companions array
      batch.update(invitationRef, {
        'companions': FieldValue.arrayUnion([companionEntry]),
        'companionsCount':
            (invitationData['companionsCount'] ?? 0), // or keep existing
        'companionsSubmittedAt': FieldValue.serverTimestamp(),
        'modifiedAt': FieldValue.serverTimestamp(),
      });
      // Step 5: Commit batch atomically
      await batch.commit();

      print(
          '✅ Companion created and linked atomically: guestId=$guestId, groupId=$groupId');
      return guestId;
    } on FirebaseException catch (e) {
      print('❌ Firestore error creating companion: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error creating companion: $e');
      rethrow;
    }
  }

  /// Updates the isInvited flag for multiple guests atomically
  ///
  /// This method uses a Firestore batch write to update multiple guest documents
  /// in a single atomic operation. All updates succeed or fail together.
  ///
  /// Parameters:
  /// - [guestIds]: List of guest IDs to update (required)
  ///
  /// Returns:
  /// - Number of guests updated
  /// - Throws FirebaseException on Firestore errors
  Future<int> updateGuestsInvitedStatus(List<String> guestIds) async {
    if (guestIds.isEmpty) {
      return 0;
    }

    try {
      final batch = _db.batch();
      int updateCount = 0;

      for (final guestId in guestIds) {
        if (guestId.isEmpty) continue;

        final guestRef = guestsRef.doc(guestId);
        batch.update(guestRef, {
          'isInvited': true,
          'modifiedAt': FieldValue.serverTimestamp(),
        });
        updateCount++;
      }

      if (updateCount > 0) {
        await batch.commit();
        print('✅ Updated isInvited flag for $updateCount guest(s)');
      }

      return updateCount;
    } on FirebaseException catch (e) {
      print('❌ Firestore error updating guests invited status: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error updating guests invited status: $e');
      rethrow;
    }
  }

  /// Gets the groupId for a main guest by their guestId
  ///
  /// Parameters:
  /// - [mainGuestId]: The main guest's guestId (required)
  ///
  /// Returns:
  /// - The groupId if found, null otherwise
  /// - Throws FirebaseException on Firestore errors
  Future<String?> getGroupIdForMainGuest(String mainGuestId) async {
    try {
      final mainGuestQuery = await guestsRef
          .where('guestId', isEqualTo: mainGuestId)
          .limit(1)
          .get();

      if (mainGuestQuery.docs.isEmpty) {
        return null;
      }

      final mainGuestData = mainGuestQuery.docs.first.data();
      return mainGuestData['groupId'] as String?;
    } on FirebaseException catch (e) {
      print('❌ Firestore error getting groupId for main guest: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error getting groupId for main guest: $e');
      rethrow;
    }
  }

  /// Gets the count of existing companions for a given groupId
  ///
  /// Parameters:
  /// - [groupId]: The groupId to query (required)
  ///
  /// Returns:
  /// - Number of companions (guests with isCompanion=true) with this groupId
  /// - Throws FirebaseException on Firestore errors
  Future<int> getCompanionCountByGroupId(String groupId) async {
    try {
      final groupGuestsQuery = await guestsRef
          .where('groupId', isEqualTo: groupId)
          .where('isCompanion', isEqualTo: true)
          .get();

      return groupGuestsQuery.docs.length;
    } on FirebaseException catch (e) {
      print(
          '❌ Firestore error getting companion count by groupId: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error getting companion count by groupId: $e');
      rethrow;
    }
  }

  /// Gets an invitation document by ID
  ///
  /// Parameters:
  /// - [invitationId]: The invitation document ID (required)
  ///
  /// Returns:
  /// - The invitation data map if found, null otherwise
  /// - Throws FirebaseException on Firestore errors
  Future<Map<String, dynamic>?> getInvitationById(String invitationId) async {
    try {
      final invitationDoc =
          await _db.collection('invitations').doc(invitationId).get();

      if (!invitationDoc.exists) {
        return null;
      }

      return invitationDoc.data();
    } on FirebaseException catch (e) {
      print('❌ Firestore error getting invitation: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error getting invitation: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Guest Login Validation
  // ---------------------------------------------------------------------------

  /// Validates guest login by fetching event and guest simultaneously.
  ///
  /// Returns a map containing both event and guest data if found, or null if either is missing.
  ///
  /// Parameters:
  /// - [invitationCode]: The invitation code from the event (e.g., "MI9289UL")
  /// - [batchId]: The batch ID assigned to the guest (e.g., "223322")
  ///
  /// Returns:
  /// ```dart
  /// {
  ///   'event': Event,
  ///   'guest': GuestModel,
  /// }
  /// ```
  /// or `null` if validation fails.
  ///
  /// Note: Uses a transaction to ensure data consistency if we need to update
  /// guest/invitation status in the future.
  Future<Map<String, dynamic>?> validateGuestLogin({
    required String invitationCode,
    required String batchId,
  }) async {
    try {
      final code = invitationCode.trim().toUpperCase();
      final batch = batchId.trim();

      if (code.isEmpty || batch.isEmpty) {
        print('❌ Missing invitationCode or batchId');
        return null;
      }

      // ✅ 1) Find invitation by PER-GUEST invitation code
      final invSnap = await _db
          .collection('invitations')
          .where('invitationCode', isEqualTo: code)
          .limit(1)
          .get();

      if (invSnap.docs.isEmpty) {
        print('❌ No invitation found with code: $code');
        return null;
      }

      final invDoc = invSnap.docs.first;
      final inv = invDoc.data();

      // ✅ 2) Expiry check (if stored)
      final expiresAt = inv['expiresAt'];
      if (expiresAt is Timestamp) {
        final expired = expiresAt.toDate().isBefore(DateTime.now());
        if (expired) {
          print('❌ Invitation code expired');
          return null;
        }
      }

      // ✅ 3) Verify batchId matches invitation (if invitation has batchId)
      final invBatchId = (inv['batchId'] ?? '').toString().trim();
      if (invBatchId.isNotEmpty && invBatchId != batch) {
        print('❌ Batch ID mismatch for invitation code');
        return null;
      }

      // ✅ 4) Load guest
      final invGuestId = (inv['guestId'] ?? '').toString().trim();

      GuestModel guest;
      if (invGuestId.isNotEmpty) {
        final gDoc = await guestsRef.doc(invGuestId).get();
        if (!gDoc.exists) {
          print('❌ Guest not found for guestId=$invGuestId');
          return null;
        }
        guest = GuestModel.fromFirestore(gDoc.data()!, gDoc.id);

        // Extra safety: if guest has batchId, ensure it matches input
        final guestBatchId = (guest.batchId ?? '').trim();
        if (guestBatchId.isNotEmpty && guestBatchId != batch) {
          print('❌ Batch ID mismatch for guest');
          return null;
        }
      } else {
        // Fallback: if invitation guestId missing, locate guest by batchId
        final gSnap =
            await guestsRef.where('batchId', isEqualTo: batch).limit(1).get();
        if (gSnap.docs.isEmpty) {
          print('❌ No guest found with batchId: $batch');
          return null;
        }
        final gDoc = gSnap.docs.first;
        guest = GuestModel.fromFirestore(gDoc.data(), gDoc.id);
      }

      // ✅ 5) Load event
      final eventId = (inv['eventId'] ?? '').toString().trim();
      if (eventId.isEmpty) {
        print('❌ Invitation missing eventId');
        return null;
      }

      final eDoc = await eventsRef.doc(eventId).get();
      if (!eDoc.exists) {
        print('❌ Event not found for eventId=$eventId');
        return null;
      }

      final event = Event.fromFirestore(eDoc);

      // ✅ 6) Ensure guest belongs to event
      if (guest.eventId != event.eventId) {
        print('❌ Guest does not belong to this event');
        return null;
      }

      print('✅ Guest login validated successfully (by invitationCode)');
      return {
        'event': event,
        'guest': guest,
        'invitationId': invDoc.id,
        'token': (inv['token'] ?? '').toString().trim(),
      };
    } on FirebaseException catch (e) {
      print('❌ Firestore error during guest login validation: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error during guest login validation: $e');
      rethrow;
    }
  }

  // -----------------------------
  // Hosts: Event assignment helpers
  // -----------------------------

  Future<void> addHostToEvent({
    required String eventId,
    required String hostUid,
  }) async {
    final ref = await _eventRefByEventId(eventId);
    await ref.update({
      'hostUserIds': FieldValue.arrayUnion([hostUid.trim()]),
      'modifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setPrimaryHostForEvent({
    required String eventId,
    required String hostUid,
  }) async {
    final ref = await _eventRefByEventId(eventId);
    await ref.update({
      'primaryHostUserId': hostUid.trim(),
      'hostUserIds': FieldValue.arrayUnion([hostUid.trim()]),
      'modifiedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Removes host from event.
  /// If primary host is removed, picks a new primary from remaining hosts.
  Future<void> removeHostFromEvent({
    required String eventId,
    required String hostUid,
  }) async {
    final ref = await _eventRefByEventId(eventId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('Event not found');

      final data = (snap.data() as Map<String, dynamic>? ?? {});
      final currentHosts = (data['hostUserIds'] as List<dynamic>? ?? [])
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final uid = hostUid.trim();
      if (!currentHosts.contains(uid)) return;

      if (currentHosts.length <= 1) {
        throw Exception('At least one host must remain.');
      }

      final newHosts = currentHosts.where((x) => x != uid).toList();

      final currentPrimary =
          (data['primaryHostUserId'] ?? '').toString().trim();
      String? newPrimary = currentPrimary.isEmpty ? null : currentPrimary;

      // If removed primary, set new primary to first remaining
      if (newPrimary == uid) {
        newPrimary = newHosts.isNotEmpty ? newHosts.first : null;
      }

      tx.update(ref, {
        'hostUserIds': newHosts,
        'primaryHostUserId': newPrimary,
        'modifiedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
