// lib/controller/admin_controllers/question_sets_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:traxx_wepapp/models/question_set.dart';

class QuestionSetsController {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  QuestionSetsController({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference get _setsCol => _db.collection('demographicQuestionSets');

  /// Stream all sets for the signed-in user
  Stream<List<QuestionSet>> streamQuestionSets() {
    if (_uid == null) return const Stream.empty();

    final query = _setsCol
        .where('userId', isEqualTo: _uid)
        .where('isDisabled', isEqualTo: false)
        .orderBy('createdDate', descending: true);

    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) => QuestionSet.fromDoc(
                  d)) // fromDoc now handles any snapshot type
              .toList(),
        );
  }

  /// Create a new set and return its id
  Future<String> createQuestionSet({
    required String title,
    required String celebrationType,
    required String description, // already in your signature
  }) async {
    if (_uid == null) {
      throw Exception('User not authenticated');
    }

    final doc = _setsCol.doc(); // auto id
    final now = FieldValue.serverTimestamp();

    await doc.set({
      'questionSetId': doc.id, // 👈 store id explicitly
      'title': title,
      'celebrationType': celebrationType,
      'description': description, // 👈 short description
      'userId': _uid,
      'isDisabled': false,
      'createdDate': now,
      'modifiedDate': now,
    });

    return doc.id;
  }
}
