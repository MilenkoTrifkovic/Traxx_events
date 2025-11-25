// lib/controllers/host_questions_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/models/host_questions.dart';
import 'package:traxx_wepapp/models/host_questions_option.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HostQuestionsController {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  HostQuestionsController({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Live stream of all active demographic questions + their options
  Stream<List<DemographicQuestionWithOptions>> streamQuestions({
    String? companyId,
    String? eventId,
  }) {
    Query questionsQuery = _db
        .collection('demographicQuestions')
        .where('isDisabled', isEqualTo: false)
        .orderBy('displayOrder');

    if (companyId != null && companyId.isNotEmpty) {
      questionsQuery = questionsQuery.where('companyId', isEqualTo: companyId);
    }
    if (eventId != null && eventId.isNotEmpty) {
      questionsQuery = questionsQuery.where('eventId', isEqualTo: eventId);
    }

    return questionsQuery.snapshots().asyncMap(
      (snapshot) async {
        final questions = snapshot.docs
            .map((doc) => DemographicQuestion.fromDoc(doc))
            .toList();

        if (questions.isEmpty) return <DemographicQuestionWithOptions>[];

        final List<DemographicQuestionWithOptions> result = [];

        for (final q in questions) {
          final optsSnap = await _db
              .collection('demographicQuestionOptions')
              .where('questionId', isEqualTo: q.questionId)
              .where('isDisabled', isEqualTo: false)
              .orderBy('displayOrder')
              .get();

          final options = optsSnap.docs
              .map((doc) => DemographicQuestionOption.fromDoc(doc))
              .toList();

          result.add(
            DemographicQuestionWithOptions(
              question: q,
              options: options,
            ),
          );
        }

        return result;
      },
    );
  }

  // ────────────────────────────────────────────────────────────────
  // CREATE question + options
  // ────────────────────────────────────────────────────────────────
  Future<void> createQuestionWithOptions({
    required String questionText,
    required String questionCategory,
    required String questionType,
    required bool isRequired,
    required String companyId,
    required String eventId,
    required List<NewOptionInput> options,
  }) async {
    if (_uid == null) {
      throw Exception('User not authenticated');
    }

    final batch = _db.batch();
    final questionsCol = _db.collection('demographicQuestions');
    final optionsCol = _db.collection('demographicQuestionOptions');

    final questionDoc = questionsCol.doc(); // use generated id
    final String questionId = questionDoc.id;

    final now = FieldValue.serverTimestamp();

    batch.set(questionDoc, {
      'questionId': questionId,
      'questionText': questionText,
      'questionType': questionType, // single_select / multi_select / text
      'questionCategory': questionCategory,
      'companyId': companyId,
      'eventId': eventId,
      'userId': _uid,
      'displayOrder': 1, // you can compute later
      'isRequired': isRequired,
      'isDisabled': false,
      'createdDate': now,
      'modifiedDate': now,
    });

    for (int i = 0; i < options.length; i++) {
      final opt = options[i];
      final optDoc = optionsCol.doc();
      batch.set(optDoc, {
        'questionId': questionId,
        'label': opt.label,
        'value': opt.value,
        'optionType': opt.requiresFreeText ? 'other_with_text' : 'choice',
        'requiresFreeText': opt.requiresFreeText,
        'displayOrder': i + 1,
        'isDisabled': false,
      });
    }

    await batch.commit();
  }

  // ────────────────────────────────────────────────────────────────
  // UPDATE question text / meta
  // (options can be edited with a separate screen later)
  // ────────────────────────────────────────────────────────────────
  Future<void> updateQuestion({
    required String questionDocId,
    required Map<String, dynamic> data,
  }) async {
    if (_uid == null) {
      throw Exception('User not authenticated');
    }

    final docRef = _db.collection('demographicQuestions').doc(questionDocId);
    await docRef.update({
      ...data,
      'modifiedDate': FieldValue.serverTimestamp(),
    });
  }

  // ────────────────────────────────────────────────────────────────
  // DELETE question + all its options
  // ────────────────────────────────────────────────────────────────
  Future<void> deleteQuestionWithOptions(String questionId) async {
    if (_uid == null) {
      throw Exception('User not authenticated');
    }

    final batch = _db.batch();

    final questionDoc = _db.collection('demographicQuestions').doc(questionId);
    batch.delete(questionDoc);

    final optsSnap = await _db
        .collection('demographicQuestionOptions')
        .where('questionId', isEqualTo: questionId)
        .get();

    for (final doc in optsSnap.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}

/// Helper class for new option inputs used by the dialog
class NewOptionInput {
  final String label;
  final String value;
  final bool requiresFreeText;

  NewOptionInput({
    required this.label,
    required this.value,
    this.requiresFreeText = false,
  });
}
