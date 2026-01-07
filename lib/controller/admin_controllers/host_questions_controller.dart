import 'dart:async';

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
    bool includeConditional = false,
  }) {
    final questionsQuery = _db
        .collection('demographicQuestions')
        .where('isDisabled', isEqualTo: false)
        .where('questionSetId', isEqualTo: questionSetId)
        .orderBy('displayOrder');

    final controller = StreamController<List<DemographicQuestionWithOptions>>();

    StreamSubscription? questionsSub;
    final optionSubs = <StreamSubscription>[];

    QuerySnapshot<Map<String, dynamic>>? latestQuestionsSnap;
    final Map<String, DemographicQuestionOption> optionById = {};

    bool isBaseDoc(Map<String, dynamic> data) {
      // ✅ base if parentQuestionId missing/empty
      final p = (data['parentQuestionId'] ?? '').toString().trim();
      return p.isEmpty;
    }

    List<QueryDocumentSnapshot<Map<String, dynamic>>> visibleDocs() {
      if (latestQuestionsSnap == null) return const [];
      final docs = latestQuestionsSnap!.docs;
      if (includeConditional) return docs;
      return docs.where((d) => isBaseDoc(d.data())).toList();
    }

    void emitCombined() {
      if (latestQuestionsSnap == null) return;

      final vDocs = visibleDocs();

      if (vDocs.isEmpty) {
        controller.add(<DemographicQuestionWithOptions>[]);
        return;
      }

      final questions =
          vDocs.map((d) => DemographicQuestion.fromDoc(d)).toList();

      // group options by questionId
      final Map<String, List<DemographicQuestionOption>> byQuestionId = {};
      for (final opt in optionById.values) {
        byQuestionId.putIfAbsent(opt.questionId, () => []).add(opt);
      }

      final result = <DemographicQuestionWithOptions>[];
      for (final q in questions) {
        final opts = List<DemographicQuestionOption>.from(
          byQuestionId[q.questionId] ?? const [],
        )..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        result.add(DemographicQuestionWithOptions(question: q, options: opts));
      }

      controller.add(result);
    }

    void resetOptionStreams(List<String> questionIds) {
      for (final s in optionSubs) {
        s.cancel();
      }
      optionSubs.clear();
      optionById.clear();

      if (questionIds.isEmpty) {
        emitCombined();
        return;
      }

      const chunkSize = 30;
      for (int i = 0; i < questionIds.length; i += chunkSize) {
        final chunk = questionIds.sublist(
          i,
          (i + chunkSize > questionIds.length)
              ? questionIds.length
              : i + chunkSize,
        );

        final q = _db
            .collection('demographicQuestionOptions')
            .where('isDisabled', isEqualTo: false)
            .where('questionId', whereIn: chunk);

        final sub = q.snapshots().listen((snap) {
          for (final d in snap.docs) {
            final opt = DemographicQuestionOption.fromDoc(d);
            optionById[opt.id] = opt;
          }
          emitCombined();
        });

        optionSubs.add(sub);
      }
    }

    questionsSub = questionsQuery.snapshots().listen((qsnap) {
      latestQuestionsSnap = qsnap;

      // subscribe options only for visible questions
      final ids = visibleDocs().map((d) => d.id).toList();
      resetOptionStreams(ids);

      emitCombined();
    });

    controller.onCancel = () async {
      await questionsSub?.cancel();
      for (final s in optionSubs) {
        await s.cancel();
      }
      await controller.close();
    };

    return controller.stream;
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

  /// 🔹 Create a new option for an existing question
  Future<DemographicQuestionOption> createOption({
    required String questionId,
    required int displayOrder,
  }) async {
    if (_uid == null) {
      throw Exception('User not authenticated');
    }

    final docRef = _db.collection('demographicQuestionOptions').doc();
    final now = FieldValue.serverTimestamp();

    final label = 'Option $displayOrder';
    final value = 'option_$displayOrder';

    await docRef.set({
      'questionId': questionId,
      'label': label,
      'value': value,
      'optionType': 'choice',
      'requiresFreeText': false,
      'displayOrder': displayOrder,
      'isDisabled': false,
      'createdDate': now,
      'modifiedDate': now,
    });

    return DemographicQuestionOption(
      id: docRef.id,
      questionId: questionId,
      label: label,
      value: value,
      optionType: 'choice',
      requiresFreeText: false,
      isDisabled: false,
      displayOrder: displayOrder,
    );
  }

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

  Future<void> createConditionalQuestionWithOptions({
    required String questionSetId,
    required String parentQuestionId,
    required String triggerOptionId,
    required String questionText,
    required String questionType,
    required bool isRequired,
    required List<NewOptionInput> options,
  }) async {
    if (_uid == null) throw Exception('User not authenticated');

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
      'displayOrder': 9999, // sub-question order not used in base editor
      'isRequired': isRequired,
      'isDisabled': false,
      'createdDate': now,
      'modifiedDate': now,

      // ✅ rule fields
      'parentQuestionId': parentQuestionId,
      'triggerOptionId': triggerOptionId,
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
        'createdDate': now,
        'modifiedDate': now,
      });
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
