import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/models/event.dart';
import 'package:traxx_wepapp/utils/collect_ref.dart';

class FirestoreServices {
  final _db = FirebaseFirestore.instance;

  /// Reference to users collection in Firestore
  late final CollectionReference<Map<String, dynamic>> userRef;

  /// Reference to events collection in Firestore
  late final CollectionReference<Map<String, dynamic>> eventsRef;

  /// Reference to locations collection in Firestore
  late final CollectionReference<Map<String, dynamic>> locationsRef;

  FirestoreServices() {
    userRef = _db.collection(usersCol);
    eventsRef = _db.collection(eventsCol);
    locationsRef = _db.collection(locationsCol);
  }

  /// Saves a new event to Firestore.
  ///
  /// Throws [FirebaseException] if the save operation fails.
  /// TODO: Add user authentication check and link event to user.
  Future<void> saveEvent(Event event) async {
    try {
      //Check if user logged in
      final eventDocRef = await eventsRef.add(event.toJson());
      //Add event id to user document
    } on FirebaseException catch (e) {
      print('Firestore error: ${e.message}');
      rethrow; // still rethrow but now logged
    } catch (e) {
      print('Unknown error saving event: $e');
      rethrow;
    }
  }

  Future<List<Event>> getAllEvents() async {
    // TODO after login implementation:
// - Check if the user is logged in
// - Retrieve all events assigned to the user
// - Fetch only the assigned events (Firestore rules will also apply)

    try {
      List<Event> events = [];
      final snapshot = await eventsRef.get();
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
}
