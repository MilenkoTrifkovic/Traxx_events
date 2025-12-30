import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/services/guest_firestore_services.dart';
import 'package:traxx_wepapp/utils/response_flow_helper.dart';

/// Controller for demographic response page.
/// 
/// Handles all business logic:
/// - Loading invitation & questions
/// - Validating tokens
/// - Managing answers
/// - Submitting to cloud function
/// - Navigation flow
/// - Read-only preview mode (when readOnly = true)
class DemographicResponseController extends GetxController {
  // ---------------------------------------------------------------------------
  // Dependencies
  // ---------------------------------------------------------------------------
  final GuestFirestoreServices _firestoreService = Get.find<GuestFirestoreServices>();
  final CloudFunctionsService _cloudFunctions = Get.find<CloudFunctionsService>();

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
  final questions = <DemographicQuestion>[].obs;
  final answers = <String, dynamic>{}.obs;
  final activeQuestionId = RxnString();
  final currentPersonName = ''.obs;

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
      final companion = companions[_currentCompanionIndex!] as Map<String, dynamic>?;
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
    // Dispose all text controllers
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

  /// Update an answer.
  void updateAnswer(String questionId, dynamic value) {
    answers[questionId] = value;
    answers.refresh(); // Force UI rebuild
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
    return freeTextControllers.putIfAbsent(
      key,
      () => TextEditingController(),
    );
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

    // Validate required questions
    final missing = questions.where((q) => q.isRequired && !isAnswered(q));
    if (missing.isNotEmpty) {
      _showSnackbar(context, 'Please answer all required questions');
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
          'answer': _serializeAnswer(answers[q.id]),
        };
      }).toList();

      await _cloudFunctions.submitDemographics(
        invitationId: _activeInvitationId,
        token: tokenToUse,
        answers: payloadAnswers,
        companionIndex: _currentCompanionIndex,
      );

      // Update local state
      _updateLocalStateAfterSubmit();

      // Rebuild flow state
      _flowState = ResponseFlowState.fromInvitation(
        invitation.value!,
        tokenToUse,
        invitationIdOverride: _activeInvitationId,
      );

      // Navigate
      _navigateToNextStep(context, tokenToUse);
      
    } on FirebaseFunctionsException catch (e) {
      _showSnackbar(context, 'Submit failed: ${e.message ?? e.code}', isError: true);
    } catch (e) {
      _showSnackbar(context, 'Submit failed: $e', isError: true);
    } finally {
      isSubmitting.value = false;
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
        if (_currentCompanionIndex! < 0 || _currentCompanionIndex! >= companions.length) {
          _setError('Invalid companion', 'The specified companion does not exist.');
          return;
        }
        
        final companion = companions[_currentCompanionIndex!] as Map<String, dynamic>;
        currentPersonName.value = 
            _firestoreService.getCompanionName(companion, _currentCompanionIndex!);
        
        // Already submitted?
        if (companion['demographicSubmitted'] == true) {
          isLoading.value = false;
          return;
        }
      } else {
        currentPersonName.value = _firestoreService.getMainGuestName(inv);
        
        // Already submitted?
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
      final questionSetId = await _firestoreService.getQuestionSetId(
        inv,
        allowEventFallback: showInvitationInput,
      );

      if (questionSetId == null || questionSetId.isEmpty) {
        _setError('Questions not assigned',
            'This invitation is missing a demographic question set. Please ask the host to resend the invite.');
        return;
      }

      // 8) Fetch question set
      final qs = await _firestoreService.getDemographicQuestionSet(questionSetId);
      if (qs == null) {
        _setError('Question set not found',
            'This invitation points to a missing question set.');
        return;
      }
      questionSet.value = qs;

      // 9) Fetch questions
      final loadedQuestions = await _firestoreService.getDemographicQuestions(questionSetId);
      if (loadedQuestions.isEmpty) {
        questions.clear();
        isLoading.value = false;
        return;
      }

      // 10) Fetch options
      final questionIds = loadedQuestions.map((q) => q.id).toList();
      final optionsMap = await _firestoreService.getDemographicOptions(questionIds);

      // 11) Build questions with options & init answers
      questions.clear();
      answers.clear();

      for (final q in loadedQuestions) {
        q.options = optionsMap[q.id] ?? [];
        questions.add(q);

        // Initialize answers based on type
        if (q.type == 'short_answer' || q.type == 'paragraph') {
          answers[q.id] = '';
          textControllers[q.id] = TextEditingController(text: '');
        } else if (q.type == 'checkboxes') {
          answers[q.id] = <Map<String, dynamic>>[];
        } else {
          answers[q.id] = null;
        }
      }

      // 12) Set active question
      activeQuestionId.value = questions.isNotEmpty ? questions.first.id : null;
      isLoading.value = false;

    } catch (e, st) {
      debugPrint('Demographic load error: $e');
      debugPrint('$st');
      _setError('Something went wrong',
          'We could not load the questions right now. Please refresh and try again.');
    }
  }

  /// Load questions only (read-only mode) - no invitation needed.
  /// Used for previewing question sets in admin panel.
  Future<void> loadQuestionsOnly(String qsId) async {
    _setLoading();

    // Clear previous text controllers
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

      // 2) Fetch questions
      final loadedQuestions = await _firestoreService.getDemographicQuestions(qsId);
      if (loadedQuestions.isEmpty) {
        questions.clear();
        isLoading.value = false;
        return;
      }

      // 3) Fetch options
      final questionIds = loadedQuestions.map((q) => q.id).toList();
      final optionsMap = await _firestoreService.getDemographicOptions(questionIds);

      // 4) Build questions with options (no answers in read-only mode)
      questions.clear();
      answers.clear();

      for (final q in loadedQuestions) {
        q.options = optionsMap[q.id] ?? [];
        questions.add(q);
        
        // Initialize empty answers for display purposes
        if (q.type == 'checkboxes') {
          answers[q.id] = <Map<String, dynamic>>[];
        } else {
          answers[q.id] = null;
        }
      }

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
    questions.clear();
    answers.clear();
    activeQuestionId.value = null;
    errorTitle.value = title;
    errorMessage.value = message;
  }

  int? _readCompanionIndexFromUrl() {
    // 1) normal query param
    final idx = Uri.base.queryParameters['companionIndex'];
    if (idx != null && idx.isNotEmpty) {
      return int.tryParse(idx);
    }

    // 2) hash route support: "#/demographics?...&companionIndex=0"
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
    // 1) widget token
    final t1 = token.trim();
    if (t1.isNotEmpty) return t1;

    // 2) normal query param
    final t2 = (Uri.base.queryParameters['token'] ?? '').trim();
    if (t2.isNotEmpty) return t2;

    // 3) hash route support
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

  dynamic _serializeAnswer(dynamic answer) {
    if (answer is String) return answer.trim();
    return answer;
  }

  void _updateLocalStateAfterSubmit() {
    if (_currentCompanionIndex == null) {
      // Main guest
      invitation.value = {...?invitation.value, 'used': true};
    } else {
      // Companion
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
    final nextStep = flowState.getNextStep();
    final nextUrl = nextStep.buildUrl(_activeInvitationId, tokenToUse);

    debugPrint('Demographics: Navigating to next step: ${nextStep.step}, '
        'companionIndex: ${nextStep.companionIndex}, url: $nextUrl');
    context.go(nextUrl);
  }

  void _showSnackbar(BuildContext context, String message, {bool isError = false}) {
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
