import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:traxx_wepapp/models/host_questions.dart';
import 'package:traxx_wepapp/models/host_questions_option.dart';

class HostQuestionsController {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  HostQuestionsController({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Live stream of all questions + options for a given set
  Stream<List<DemographicQuestionWithOptions>> streamQuestions({
    required String questionSetId,
  }) {
    Query questionsQuery = _db
        .collection('demographicQuestions')
        .where('isDisabled', isEqualTo: false)
        .where('questionSetId', isEqualTo: questionSetId)
        .orderBy('displayOrder');

    return questionsQuery.snapshots().asyncMap((snapshot) async {
      final questions =
          snapshot.docs.map((doc) => DemographicQuestion.fromDoc(doc)).toList();

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
    });
  }

  Future<void> updateOption({
    required String optionDocId,
    required Map<String, dynamic> data,
  }) async {
    if (_uid == null) {
      throw Exception('User not authenticated');
    }

    final docRef =
        _db.collection('demographicQuestionOptions').doc(optionDocId);

    await docRef.update({
      ...data,
      'modifiedDate': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteOption(String optionId) async {
    if (_uid == null) {
      throw Exception('User not authenticated');
    }
    await _db.collection('demographicQuestionOptions').doc(optionId).delete();
  }

  // CREATE question + options
  Future<void> createQuestionWithOptions({
    required String questionSetId,
    required String questionText,
    required String questionType,
    required bool isRequired,
    required List<NewOptionInput> options,
  }) async {
    if (_uid == null) {
      throw Exception('User not authenticated');
    }

    final batch = _db.batch();
    final questionsCol = _db.collection('demographicQuestions');
    final optionsCol = _db.collection('demographicQuestionOptions');

    final questionDoc = questionsCol.doc();
    final String questionId = questionDoc.id;

    final now = FieldValue.serverTimestamp();

    batch.set(questionDoc, {
      'questionId': questionId,
      'questionSetId': questionSetId,
      'questionText': questionText,
      'questionType': questionType,
      'userId': _uid,
      'displayOrder': 1, // we recompute later when reordering
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

/// Helper class for new option inputs
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
