import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/services/guest_firestore_services.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/utils/response_flow_helper.dart';

class DemographicResponseController extends GetxController {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  final GuestFirestoreServices _firestoreService =
      Get.find<GuestFirestoreServices>();
  final CloudFunctionsService _cloudFunctions =
      Get.find<CloudFunctionsService>();

  // ---------------------------------------------------------------------------
  // Constructor parameters
  // ---------------------------------------------------------------------------
  final String invitationId;
  final String token;
  final int? companionIndex;
  final String? companionName;
  final bool showInvitationInput;

  /// Read-only mode - just display questions without interaction
  final bool readOnly;

  /// Question set ID - used when readOnly = true (no invitation needed)
  final String? questionSetId;

  DemographicResponseController({
    this.invitationId = '',
    this.token = '',
    this.companionIndex,
    this.companionName,
    this.showInvitationInput = false,
    this.readOnly = false,
    this.questionSetId,
  });

  // ---------------------------------------------------------------------------
  // Reactive State
  // ---------------------------------------------------------------------------
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final errorTitle = RxnString();
  final errorMessage = RxnString();

  final invitation = Rxn<Map<String, dynamic>>();
  final questionSet = Rxn<Map<String, dynamic>>();

  /// ✅ All questions from Firestore (base + conditional)
  final allQuestions = <DemographicQuestion>[].obs;

  /// ✅ Visible questions (base + triggered conditional) used by UI and submit
  final questions = <DemographicQuestion>[].obs;

  /// Answers keyed by questionId.
  /// IMPORTANT for rules:
  /// - single select should store optionDocId as String
  /// - or Map { optionId: <docId>, ... } if freeText is involved
  /// - checkboxes can store List<String> or List<Map> containing optionId
  final answers = <String, dynamic>{}.obs;

  final activeQuestionId = RxnString();
  final currentPersonName = ''.obs;

  /// Track validation errors for each question
  final validationErrors = <String, String>{}.obs;

  /// Track if validation was attempted (to show errors)
  final showValidation = false.obs;

  /// Trigger for scrolling to first error (increments each validation)
  final validationTrigger = 0.obs;
  String? _firstErrorQuestionId;
  String? get firstErrorQuestionId => _firstErrorQuestionId;

  // Text controllers need manual management
  final Map<String, TextEditingController> textControllers = {};
  final Map<String, TextEditingController> freeTextControllers = {};

  // Flow state
  ResponseFlowState? _flowState;

  // Active invitation ID (can be different from widget if using input)
  String _activeInvitationId = '';
  String get activeInvitationId => _activeInvitationId;

  // Current companion index being processed
  int? _currentCompanionIndex;
  int? get currentCompanionIndex => _currentCompanionIndex;

  // ---------------------------------------------------------------------------
  // Computed Properties
  // ---------------------------------------------------------------------------
  bool get hasError => errorTitle.value != null;

  bool get isCurrentPersonDone {
    final inv = invitation.value;
    if (inv == null) return false;

    if (_currentCompanionIndex == null) {
      return inv['used'] == true;
    } else {
      final companions = (inv['companions'] as List?) ?? [];
      if (_currentCompanionIndex! >= companions.length) return false;
      final companion =
          companions[_currentCompanionIndex!] as Map<String, dynamic>?;
      return companion?['demographicSubmitted'] == true;
    }
  }

  String get questionSetTitle =>
      (questionSet.value?['title'] ?? 'Demographics').toString();

  String get questionSetDescription =>
      (questionSet.value?['description'] ?? '').toString();

  int get totalPeople {
    final companions = (invitation.value?['companions'] as List?) ?? [];
    return 1 + companions.length;
  }

  int get completedCount {
    final inv = invitation.value;
    if (inv == null) return 0;

    int count = 0;
    if (inv['used'] == true) count++;

    final companions = (inv['companions'] as List?) ?? [];
    for (final c in companions) {
      if ((c as Map)['demographicSubmitted'] == true) count++;
    }
    return count;
  }

  int get currentPersonNumber =>
      _currentCompanionIndex == null ? 1 : (_currentCompanionIndex! + 2);

  bool get hasCompanions =>
      ((invitation.value?['companions'] as List?) ?? []).isNotEmpty;

  String get fillingForLabel {
    if (_currentCompanionIndex != null) {
      final name = currentPersonName.value.isNotEmpty
          ? currentPersonName.value
          : 'Companion ${_currentCompanionIndex! + 1}';
      return 'Filling for: $name';
    } else {
      return 'Filling for: You';
    }
  }

  bool _isSub(DemographicQuestion q) =>
      (q.parentQuestionId?.trim().isNotEmpty ?? false) &&
      (q.triggerOptionId?.trim().isNotEmpty ?? false);

  bool _isBase(DemographicQuestion q) => !_isSub(q);

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------
  @override
  void onInit() {
    super.onInit();
    debugPrint(
      '*** DemographicResponseController init. invitationId=$invitationId '
      'companionIndex=$companionIndex readOnly=$readOnly questionSetId=$questionSetId',
    );

    // Read-only mode: just load questions by questionSetId
    if (readOnly && questionSetId != null && questionSetId!.isNotEmpty) {
      loadQuestionsOnly(questionSetId!);
      return;
    }

    _currentCompanionIndex = companionIndex ?? _readCompanionIndexFromUrl();
    _activeInvitationId = invitationId.trim();

    if (_activeInvitationId.isEmpty) {
      isLoading.value = false;
    } else {
      loadData(_activeInvitationId);
    }
  }

  @override
  void onClose() {
    for (final c in textControllers.values) {
      c.dispose();
    }
    for (final c in freeTextControllers.values) {
      c.dispose();
    }
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // Public Methods
  // ---------------------------------------------------------------------------

  /// Reload with a different invitation ID (used by host demo mode).
  void loadForInvitation(String newInvitationId) {
    final id = newInvitationId.trim();
    if (id.isEmpty) return;
    _activeInvitationId = id;
    loadData(id);
  }

  /// Reload data when companion index changes.
  void updateCompanionIndex(int? newIndex) {
    if (newIndex == _currentCompanionIndex) return;
    debugPrint('DemographicController: companionIndex changed to $newIndex');
    _currentCompanionIndex = newIndex;
    loadData(_activeInvitationId);
  }

  /// Set the active question (for expanded card state).
  void setActiveQuestion(String id) {
    if (activeQuestionId.value == id) return;
    activeQuestionId.value = id;
  }

  /// Update an answer and recompute conditional visibility.
  void updateAnswer(String questionId, dynamic value) {
    answers[questionId] = value;
    answers.refresh();

    // Clear validation error for this question when answered
    if (validationErrors.containsKey(questionId)) {
      validationErrors.remove(questionId);
    }

    recomputeVisibleQuestions(); // ✅ conditional sub-questions
  }

  /// Get text controller for short_answer/paragraph questions.
  TextEditingController getTextController(String questionId) {
    return textControllers.putIfAbsent(
      questionId,
      () => TextEditingController(text: (answers[questionId] ?? '').toString()),
    );
  }

  /// Get free text controller for "other" option.
  TextEditingController getFreeTextController(String key) {
    return freeTextControllers.putIfAbsent(key, () => TextEditingController());
  }

  /// Check if a question is answered (for validation).
  bool isAnswered(DemographicQuestion q) {
    final v = answers[q.id];

    if (q.type == 'short_answer' || q.type == 'paragraph') {
      return (v ?? '').toString().trim().isNotEmpty;
    }

    if (q.type == 'checkboxes') {
      final list = (v as List?) ?? const [];
      if (list.isEmpty) return false;

      // if there is an "other" item requiring free text, enforce it
      for (final item in list) {
        if (item is Map && (item['requiresFreeText'] == true)) {
          final ft = (item['freeText'] ?? '').toString().trim();
          if (ft.isEmpty) return false;
        }
      }
      return true;
    }

    if (v == null) return false;

    if (v is Map && (v['requiresFreeText'] == true)) {
      final ft = (v['freeText'] ?? '').toString().trim();
      if (ft.isEmpty) return false;
    }

    return v.toString().trim().isNotEmpty;
  }

  /// Get validation error message for a specific question
  String? getValidationError(DemographicQuestion q) {
    if (!q.isRequired) return null;
    if (isAnswered(q)) return null;

    final v = answers[q.id];

    // Check for "Other" option requiring free text
    if (q.type == 'checkboxes') {
      final list = (v as List?) ?? const [];
      for (final item in list) {
        if (item is Map && (item['requiresFreeText'] == true)) {
          final ft = (item['freeText'] ?? '').toString().trim();
          if (ft.isEmpty) {
            return 'Please provide additional details for your selection';
          }
        }
      }
      if (list.isEmpty) {
        return 'Please select at least one option';
      }
    }

    if (v is Map && (v['requiresFreeText'] == true)) {
      final ft = (v['freeText'] ?? '').toString().trim();
      if (ft.isEmpty) {
        return 'Please provide additional details for your selection';
      }
    }

    // Default messages by type
    switch (q.type) {
      case 'short_answer':
      case 'paragraph':
        return 'Please enter your answer';
      case 'multiple_choice':
      case 'dropdown':
        return 'Please select an option';
      case 'checkboxes':
        return 'Please select at least one option';
      default:
        return 'This field is required';
    }
  }

  /// Validate all required questions and return the first unanswered question ID
  String? validateRequiredQuestions() {
    validationErrors.clear();
    String? firstUnansweredId;

    for (final q in questions) {
      if (q.isRequired && !isAnswered(q)) {
        final error = getValidationError(q);
        if (error != null) {
          validationErrors[q.id] = error;
          firstUnansweredId ??= q.id;
        }
      }
    }

    showValidation.value = validationErrors.isNotEmpty;
    _firstErrorQuestionId = firstUnansweredId;

    // Increment trigger to notify listeners even if showValidation stays true
    if (firstUnansweredId != null) {
      validationTrigger.value++;
    }

    return firstUnansweredId;
  }

  /// Submit demographics and navigate to next step.
  Future<void> submitAndContinue(BuildContext context) async {
    if (isSubmitting.value) return;

    final tokenFromUrl = _resolveToken();
    final tokenInInvite = (invitation.value?['token'] ?? '').toString().trim();

    // Validation
    if (tokenInInvite.isEmpty) {
      _showSnackbar(context, 'Invalid invitation (missing token)');
      return;
    }

    final requireToken = !showInvitationInput;
    if (requireToken && tokenFromUrl != tokenInInvite) {
      _showSnackbar(context, 'Invalid token in link');
      return;
    }

    final tokenToUse = requireToken
        ? tokenFromUrl
        : (tokenFromUrl.isNotEmpty ? tokenFromUrl : tokenInInvite);

    // Already submitted - just navigate
    if (isCurrentPersonDone) {
      _navigateToNextStep(context, tokenToUse);
      return;
    }

    // Validate required VISIBLE questions (includes triggered sub-questions)
    final firstUnansweredId = validateRequiredQuestions();
    if (firstUnansweredId != null) {
      _showSnackbar(context, 'Please answer all required questions');
      // The page will scroll to the first unanswered question via the UI
      return;
    }

    isSubmitting.value = true;

    try {
      final payloadAnswers = questions.map((q) {
        return <String, dynamic>{
          'questionId': q.id,
          'questionText': q.text,
          'type': q.type,
          'isRequired': q.isRequired,
          'answer': _serializeAnswerForQuestion(q, answers[q.id]),
        };
      }).toList();

      final resp = await _cloudFunctions.submitDemographics(
        invitationId: _activeInvitationId,
        token: tokenToUse,
        answers: payloadAnswers,
        companionIndex: _currentCompanionIndex,
      );

// ✅ If skipped (not attending), do NOT mark demographicSubmitted
      if (resp['skipped'] == true) {
        _navigateToNextStep(context, tokenToUse);
        return;
      }

// ✅ Normal success or alreadySubmitted
      if (resp['alreadySubmitted'] != true) {
        _updateLocalStateAfterSubmit();
      }

      _flowState = ResponseFlowState.fromInvitation(
        invitation.value!,
        tokenToUse,
        invitationIdOverride: _activeInvitationId,
      );

      _navigateToNextStep(context, tokenToUse);
    } on FirebaseFunctionsException catch (e) {
      final msg = (e.message ?? '').toLowerCase();

      if (_currentCompanionIndex != null &&
          e.code == 'failed-precondition' &&
          msg.contains('attendance')) {
        context.go(
          '${AppRoute.companionRsvp.path}'
          '?invitationId=${Uri.encodeComponent(_activeInvitationId)}'
          '&token=${Uri.encodeComponent(tokenToUse)}'
          '&companionIndex=$_currentCompanionIndex',
        );
        return;
      }

      _showSnackbar(context, 'Submit failed: ${e.message ?? e.code}',
          isError: true);
    } catch (e) {
      _showSnackbar(context, 'Submit failed: $e', isError: true);
    } finally {
      isSubmitting.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Conditional rules logic (core)
  // ---------------------------------------------------------------------------

  void _ensureAnswerInitialized(DemographicQuestion q) {
    if (answers.containsKey(q.id)) return;

    if (q.type == 'short_answer' || q.type == 'paragraph') {
      answers[q.id] = '';
      if (!readOnly) {
        textControllers.putIfAbsent(
            q.id, () => TextEditingController(text: ''));
      }
    } else if (q.type == 'checkboxes') {
      answers[q.id] = <Map<String, dynamic>>[];
    } else {
      answers[q.id] = null;
    }
  }

  /// Extract selected optionIds for rules.
  /// Rule matching uses option document IDs (triggerOptionId).
  Set<String> _selectedOptionIdsForQuestion(DemographicQuestion q) {
    final v = answers[q.id];
    if (v == null) return {};

    // Single select stored as optionId string
    if (v is String) {
      final s = v.trim();
      return s.isEmpty ? {} : {s};
    }

    // Single select stored as map { optionId, ... }
    if (v is Map) {
      final optId = v['optionId'];
      if (optId is String && optId.trim().isNotEmpty) return {optId.trim()};
      return {};
    }

    // Checkboxes stored as list
    if (v is List) {
      final out = <String>{};
      for (final item in v) {
        if (item is String && item.trim().isNotEmpty) {
          out.add(item.trim());
        } else if (item is Map) {
          final optId = item['optionId'];
          if (optId is String && optId.trim().isNotEmpty) out.add(optId.trim());
        }
      }
      return out;
    }

    return {};
  }

  void _clearAnswerForQuestion(String questionId) {
    answers.remove(questionId);
    textControllers.remove(questionId)?.dispose();
    freeTextControllers.remove(questionId)?.dispose();
  }

  /// ✅ Base questions always visible.
  /// ✅ Sub-questions visible only when parent answer includes triggerOptionId.
  void recomputeVisibleQuestions() {
    if (allQuestions.isEmpty) {
      questions.clear();
      return;
    }

    final base = allQuestions.where(_isBase).toList()
      ..sort((a, b) {
        final d = a.displayOrder.compareTo(b.displayOrder);
        if (d != 0) return d;
        return a.id.compareTo(b.id);
      });

    final Map<String, List<DemographicQuestion>> subsByParent = {};
    for (final q in allQuestions.where(_isSub)) {
      final parent = (q.parentQuestionId ?? '').trim();
      if (parent.isEmpty) continue;
      subsByParent.putIfAbsent(parent, () => []).add(q);
    }

    final visible = <DemographicQuestion>[];

    for (final bq in base) {
      _ensureAnswerInitialized(bq);
      visible.add(bq);

      final subs = subsByParent[bq.id] ?? const <DemographicQuestion>[];
      if (subs.isEmpty) continue;

      final selectedOptIds = _selectedOptionIdsForQuestion(bq);

      final triggered = subs.where((sq) {
        final trig = (sq.triggerOptionId ?? '').trim();
        return trig.isNotEmpty && selectedOptIds.contains(trig);
      }).toList()
        ..sort((a, b) {
          final d = a.displayOrder.compareTo(b.displayOrder);
          if (d != 0) return d;
          return a.id.compareTo(b.id);
        });

      for (final sq in triggered) {
        _ensureAnswerInitialized(sq);
        visible.add(sq);
      }
    }

    // Remove answers for hidden sub-questions
    final visibleIds = visible.map((q) => q.id).toSet();
    final hiddenSubIds = allQuestions
        .where(_isSub)
        .map((q) => q.id)
        .where((id) => !visibleIds.contains(id))
        .toList();

    for (final id in hiddenSubIds) {
      _clearAnswerForQuestion(id);
    }

    questions.assignAll(visible);

    // keep active question valid
    final current = activeQuestionId.value;
    if (current != null &&
        current.isNotEmpty &&
        !visibleIds.contains(current)) {
      activeQuestionId.value = visible.isNotEmpty ? visible.first.id : null;
    }
  }

  // ---------------------------------------------------------------------------
  // Data Loading
  // ---------------------------------------------------------------------------

  Future<void> loadData(String invitationId) async {
    _setLoading();

    // Clear previous text controllers
    for (final c in textControllers.values) c.dispose();
    for (final c in freeTextControllers.values) c.dispose();
    textControllers.clear();
    freeTextControllers.clear();

    try {
      // 1) Fetch invitation
      debugPrint('1) invitation...');
      final inv = await _firestoreService.getInvitation(invitationId);
      if (inv == null) {
        _setError('Invitation not found',
            'This link is invalid. Please request a new invite.');
        return;
      }
      invitation.value = inv;

      // 2) Validate token
      final tokenFromUrl = _resolveToken();
      final tokenInInvite = (inv['token'] ?? '').toString().trim();

      if (tokenInInvite.isEmpty) {
        _setError('Invitation not found',
            'This link is invalid. Please request a new invite.');
        return;
      }

      final requireToken = !showInvitationInput;
      if (requireToken) {
        if (tokenFromUrl.isEmpty) {
          _setError('Invalid link token',
              'This link is missing a token. Please request a new invite.');
          return;
        }
        if (tokenFromUrl != tokenInInvite) {
          _setError('Invalid link token',
              'This link token does not match the invitation.');
          return;
        }
      }

      // 3) Check expiry
      final expiresAt = inv['expiresAt'];
      if (expiresAt != null) {
        DateTime? expiryDate;
        if (expiresAt is DateTime) {
          expiryDate = expiresAt;
        } else if (expiresAt.runtimeType.toString().contains('Timestamp')) {
          expiryDate = (expiresAt as dynamic).toDate();
        }
        if (expiryDate != null && expiryDate.isBefore(DateTime.now())) {
          _setError('Link expired',
              'This invitation expired on $expiryDate. Please request a new invite.');
          return;
        }
      }

      // 4) Build flow state
      final tokenToUse = tokenFromUrl.isNotEmpty ? tokenFromUrl : tokenInInvite;
      _flowState = ResponseFlowState.fromInvitation(
        inv,
        tokenToUse,
        invitationIdOverride: _activeInvitationId,
      );

      // 5) Validate/setup companion
      final companions = (inv['companions'] as List?) ?? [];
      if (_currentCompanionIndex != null) {
        if (_currentCompanionIndex! < 0 ||
            _currentCompanionIndex! >= companions.length) {
          _setError(
              'Invalid companion', 'The specified companion does not exist.');
          return;
        }

        final companion =
            companions[_currentCompanionIndex!] as Map<String, dynamic>;
        currentPersonName.value = _firestoreService.getCompanionName(
            companion, _currentCompanionIndex!);

        if (companion['demographicSubmitted'] == true) {
          isLoading.value = false;
          return;
        }
      } else {
        currentPersonName.value = _firestoreService.getMainGuestName(inv);

        if (inv['used'] == true) {
          isLoading.value = false;
          return;
        }
      }

      // 6) Check if entire flow is complete
      if (_flowState!.isComplete) {
        isLoading.value = false;
        return;
      }

      // 7) Get question set ID
      final qsId = await _firestoreService.getQuestionSetId(
        inv,
        allowEventFallback: showInvitationInput,
      );

      if (qsId == null || qsId.isEmpty) {
        _setError('Questions not assigned',
            'This invitation is missing a demographic question set. Please ask the host to resend the invite.');
        return;
      }

      // 8) Fetch question set metadata
      final qs = await _firestoreService.getDemographicQuestionSet(qsId);
      if (qs == null) {
        _setError('Question set not found',
            'This invitation points to a missing question set.');
        return;
      }
      questionSet.value = qs;
      debugPrint('2) qsId=$qsId');
      // 9) Fetch questions (base + conditional)
      debugPrint('3) getDemographicQuestionSet...');

      final loadedQuestions =
          await _firestoreService.getDemographicQuestions(qsId);
      for (final q in loadedQuestions) {
        debugPrint(
          'Q="${q.text}" id=${q.id} parent=${q.parentQuestionId} trigger=${q.triggerOptionId}',
        );
      }
      if (loadedQuestions.isEmpty) {
        allQuestions.clear();
        questions.clear();
        isLoading.value = false;
        return;
      }

      // 10) Fetch options
      final questionIds = loadedQuestions.map((q) => q.id).toList();
      final optionsMap =
          await _firestoreService.getDemographicOptions(questionIds);

      // 11) Build allQuestions with options
      allQuestions.clear();
      questions.clear();
      answers.clear();

      for (final q in loadedQuestions) {
        q.options = optionsMap[q.id] ?? [];
        allQuestions.add(q); // ✅ IMPORTANT: allQuestions, not questions
      }

// 12) Compute visible questions (base only initially)
      recomputeVisibleQuestions();

// 13) Set active question (from visible list)
      activeQuestionId.value = questions.isNotEmpty ? questions.first.id : null;

      isLoading.value = false;
    } catch (e, st) {
      debugPrint('Demographic load error: $e');
      debugPrint('$st');
      _setError('Something went wrong', e.toString());
    }
  }

  /// Load questions only (read-only preview mode) - no invitation needed.
  Future<void> loadQuestionsOnly(String qsId) async {
    _setLoading();

    for (final c in textControllers.values) c.dispose();
    for (final c in freeTextControllers.values) c.dispose();
    textControllers.clear();
    freeTextControllers.clear();

    try {
      // 1) Fetch question set metadata
      final qs = await _firestoreService.getDemographicQuestionSet(qsId);
      if (qs == null) {
        _setError('Question set not found',
            'The specified question set does not exist.');
        return;
      }
      questionSet.value = qs;

      // 2) Fetch questions (base + conditional)
      final loadedQuestions =
          await _firestoreService.getDemographicQuestions(qsId);
      if (loadedQuestions.isEmpty) {
        allQuestions.clear();
        questions.clear();
        isLoading.value = false;
        return;
      }

      // 3) Fetch options
      final questionIds = loadedQuestions.map((q) => q.id).toList();
      final optionsMap =
          await _firestoreService.getDemographicOptions(questionIds);

      allQuestions.clear();
      questions.clear();
      answers.clear();

      for (final q in loadedQuestions) {
        q.options = optionsMap[q.id] ?? [];
        allQuestions.add(q);
      }

// In preview mode there are no answers selected,
// so only base questions should show
      recomputeVisibleQuestions();
      activeQuestionId.value = questions.isNotEmpty ? questions.first.id : null;

      isLoading.value = false;
    } catch (e, st) {
      debugPrint('Demographic loadQuestionsOnly error: $e');
      debugPrint('$st');
      _setError('Something went wrong',
          'We could not load the questions right now. Please refresh and try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Private Helpers
  // ---------------------------------------------------------------------------

  void _setLoading() {
    isLoading.value = true;
    invitation.value = null;
    questionSet.value = null;
    allQuestions.clear();
    questions.clear();
    answers.clear();
    activeQuestionId.value = null;
    errorTitle.value = null;
    errorMessage.value = null;
  }

  void _setError(String title, String message) {
    isLoading.value = false;
    invitation.value = null;
    questionSet.value = null;
    allQuestions.clear();
    questions.clear();
    answers.clear();
    activeQuestionId.value = null;
    errorTitle.value = title;
    errorMessage.value = message;
  }

  int? _readCompanionIndexFromUrl() {
    final idx = Uri.base.queryParameters['companionIndex'];
    if (idx != null && idx.isNotEmpty) {
      return int.tryParse(idx);
    }

    // hash route support: "#/demographics?...&companionIndex=0"
    final frag = Uri.base.fragment;
    final qIndex = frag.indexOf('?');
    if (qIndex >= 0 && qIndex + 1 < frag.length) {
      final queryPart = frag.substring(qIndex + 1);
      try {
        final params = Uri.splitQueryString(queryPart);
        final compIdx = params['companionIndex'];
        if (compIdx != null && compIdx.isNotEmpty) {
          return int.tryParse(compIdx);
        }
      } catch (_) {}
    }

    return null;
  }

  String _resolveToken() {
    final t1 = token.trim();
    if (t1.isNotEmpty) return t1;

    final t2 = (Uri.base.queryParameters['token'] ?? '').trim();
    if (t2.isNotEmpty) return t2;

    final frag = Uri.base.fragment;
    final qIndex = frag.indexOf('?');
    if (qIndex >= 0 && qIndex + 1 < frag.length) {
      final queryPart = frag.substring(qIndex + 1);
      try {
        final params = Uri.splitQueryString(queryPart);
        return (params['token'] ?? '').trim();
      } catch (_) {}
    }

    return '';
  }

  dynamic _serializeAnswerForQuestion(DemographicQuestion q, dynamic raw) {
    if (raw == null) return null;

    DemographicOption? findOpt(String key) {
      final k = key.trim();
      if (k.isEmpty) return null;

      // raw usually matches option docId (o.id)
      for (final o in q.options) {
        if (o.id == k) return o;
      }

      // fallback matching (in case something stored value/label)
      for (final o in q.options) {
        if (o.value == k || o.label == k) return o;
      }

      return null;
    }

    Map<String, dynamic> optToMap(
      DemographicOption o, {
      String? freeText,
      bool? requiresFreeTextOverride,
    }) {
      return {
        'optionId': o.id,
        'label': o.label,
        'value': o.value,
        'requiresFreeText': requiresFreeTextOverride ?? o.requiresFreeText,
        if (freeText != null && freeText.trim().isNotEmpty)
          'freeText': freeText.trim(),
      };
    }

    // Text
    if (q.type == 'short_answer' || q.type == 'paragraph') {
      return raw.toString().trim();
    }

    // Single choice
    if (q.type == 'multiple_choice' || q.type == 'dropdown') {
      // If UI already gave a map, normalize it
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);

        final optionId = (m['optionId'] ?? m['id'] ?? '').toString().trim();
        final freeText = (m['freeText'] ?? '').toString().trim();
        final label = (m['label'] ?? m['text'] ?? '').toString().trim();
        final value = (m['value'] ?? '').toString().trim();
        final requiresFreeText = (m['requiresFreeText'] == true) ||
            (m['requiresFreeText'] == 'true');

        // If already has label/value, keep it
        if (label.isNotEmpty || value.isNotEmpty) {
          return {
            'optionId': optionId.isNotEmpty ? optionId : (m['optionId'] ?? ''),
            'label': label.isNotEmpty ? label : value,
            'value': value.isNotEmpty ? value : label,
            'requiresFreeText': requiresFreeText,
            if (freeText.isNotEmpty) 'freeText': freeText,
          };
        }

        // Otherwise resolve by optionId
        final opt = optionId.isNotEmpty ? findOpt(optionId) : null;
        if (opt != null)
          return optToMap(opt,
              freeText: freeText, requiresFreeTextOverride: requiresFreeText);

        return m;
      }

      // raw is a string (optionId/docId) → enrich
      final key = raw.toString().trim();
      final opt = findOpt(key);
      return opt != null ? optToMap(opt) : key;
    }

    // Checkboxes (multi)
    if (q.type == 'checkboxes') {
      final list = raw is List ? raw : <dynamic>[];
      final out = <Map<String, dynamic>>[];

      for (final item in list) {
        if (item is Map) {
          final m = Map<String, dynamic>.from(item);

          final optionId = (m['optionId'] ?? m['id'] ?? '').toString().trim();
          final freeText = (m['freeText'] ?? '').toString().trim();
          final label = (m['label'] ?? m['text'] ?? '').toString().trim();
          final value = (m['value'] ?? '').toString().trim();
          final requiresFreeText = (m['requiresFreeText'] == true) ||
              (m['requiresFreeText'] == 'true');

          if (label.isNotEmpty || value.isNotEmpty) {
            out.add({
              'optionId': optionId,
              'label': label.isNotEmpty ? label : value,
              'value': value.isNotEmpty ? value : label,
              'requiresFreeText': requiresFreeText,
              if (freeText.isNotEmpty) 'freeText': freeText,
            });
            continue;
          }

          final opt = optionId.isNotEmpty ? findOpt(optionId) : null;
          if (opt != null) {
            out.add(optToMap(opt,
                freeText: freeText,
                requiresFreeTextOverride: requiresFreeText));
          }
          continue;
        }

        // item is string optionId
        final key = item.toString().trim();
        final opt = findOpt(key);
        if (opt != null) out.add(optToMap(opt));
      }

      return out;
    }

    // Fallback
    return raw is String ? raw.trim() : raw;
  }

  // dynamic _serializeAnswer(dynamic answer) {
  //   if (answer is String) return answer.trim();
  //   return answer;
  // }

  void _updateLocalStateAfterSubmit() {
    if (_currentCompanionIndex == null) {
      invitation.value = {...?invitation.value, 'used': true};
    } else {
      final companions = List<Map<String, dynamic>>.from(
        (invitation.value?['companions'] as List? ?? [])
            .map((c) => Map<String, dynamic>.from(c as Map)),
      );
      if (_currentCompanionIndex! < companions.length) {
        companions[_currentCompanionIndex!]['demographicSubmitted'] = true;
        invitation.value = {...?invitation.value, 'companions': companions};
      }
    }
  }

  void _navigateToNextStep(BuildContext context, String tokenToUse) {
    final flowState = ResponseFlowState.fromInvitation(
      invitation.value!,
      tokenToUse,
      invitationIdOverride: _activeInvitationId,
    );

    // ✅ FIRST: if complete → go to Thank You and stop
    if (flowState.isComplete) {
      context.go(
        '${AppRoute.thankYou.path}?invitationId=$_activeInvitationId&token=$tokenToUse',
      );
      return;
    }

    // Then normal routing
    final nextStep = flowState.getNextStep();
    final nextUrl = nextStep.buildUrl(_activeInvitationId, tokenToUse);

    debugPrint(
      'Demographics: Navigating to next step: ${nextStep.step}, '
      'companionIndex: ${nextStep.companionIndex}, url: $nextUrl',
    );

    context.go(nextUrl);
  }

  void _showSnackbar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red : Colors.black87,
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
