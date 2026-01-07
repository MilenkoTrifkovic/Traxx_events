import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/services/cloud_functions_services.dart';
import 'package:traxx_wepapp/utils/response_flow_helper.dart';

// If you have CloudFunctionsService in GetX, import it.
// Otherwise you can remove this import and we will call FirebaseFunctions directly.
// import 'package:your_app/services/cloud_functions_service.dart';

// ------------------------------------------------------------
// Styling constants (matches your host UI look)
// ------------------------------------------------------------
const Color kAccent = Color(0xFF6C4BFF);
const Color kBorder = Color(0xFFE5E7EB);
const Color kTextDark = Color(0xFF111827);
const Color kTextBody = Color(0xFF374151);
const Color kGfPurple = Color(0xFF673AB7);
const Color gfBackground = Color(0xFFF4F0FB);

class DemographicResponsePage extends StatefulWidget {
  final String invitationId;

  /// Token for authentication
  final String token;

  /// Companion index: null = main guest, 0+ = companion
  final int? companionIndex;

  /// Display name for companion (optional, for UI)
  final String? companionName;

  final bool showInvitationInput;
  final bool embedded;

  const DemographicResponsePage({
    super.key,
    required this.invitationId,
    this.token = '',
    this.companionIndex,
    this.companionName,
    this.showInvitationInput = false,
    this.embedded = false,
  });

  @override
  State<DemographicResponsePage> createState() =>
      _DemographicResponsePageState();
}

class _DemographicResponsePageState extends State<DemographicResponsePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _loading = true;
  bool _submitting = false;

  String _activeInvitationId = '';
  String? _activeQuestionId;
  String? _invalidTitle;
  String? _invalidMessage;

  Map<String, dynamic>? _invitation;
  Map<String, dynamic>? _questionSet;

  /// Current companion index (null = main guest, 0+ = companion)
  int? _companionIndex;

  /// Display name for current person (main guest name or companion name)
  String _currentPersonName = '';

  /// Flow state for navigation decisions
  ResponseFlowState? _flowState;

  final List<_GuestQuestion> _questions = [];
  final Map<String, dynamic> _answers = {}; // questionId -> dynamic
  final Map<String, TextEditingController> _freeTextCtrls = {}; // "other"
  final Map<String, TextEditingController> _textCtrls = {}; // short/paragraph

  late final TextEditingController _invitationIdCtrl;
  final ScrollController _listCtrl = ScrollController();

  @override
  void initState() {
    debugPrint(
      '*** DemographicResponsePage loaded. invitationId=${widget.invitationId} '
      'companionIndex=${widget.companionIndex} url=${Uri.base}',
    );
    super.initState();
    _invitationIdCtrl = TextEditingController(text: widget.invitationId);

    // Initialize companion index from widget or URL
    _companionIndex = widget.companionIndex ?? _readCompanionIndexFromUrl();

    final initial = widget.invitationId.trim();
    if (initial.isEmpty) {
      _loading = false;
      _invitation = null;
      _activeInvitationId = '';
    } else {
      _loadForInvitation(initial);
    }
  }

  @override
  void didUpdateWidget(covariant DemographicResponsePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if companion index changed (navigation to same page with different params)
    final newCompanionIndex =
        widget.companionIndex ?? _readCompanionIndexFromUrl();
    final oldCompanionIndex = _companionIndex;

    debugPrint(
        'didUpdateWidget: old companionIndex=$oldCompanionIndex, new=$newCompanionIndex');

    if (newCompanionIndex != oldCompanionIndex ||
        widget.invitationId != oldWidget.invitationId) {
      debugPrint('*** Companion index or invitation changed, reloading...');
      _companionIndex = newCompanionIndex;
      _loadForInvitation(widget.invitationId);
    }
  }

  @override
  void dispose() {
    _invitationIdCtrl.dispose();
    _listCtrl.dispose();
    for (final c in _freeTextCtrls.values) {
      c.dispose();
    }
    for (final c in _textCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Check if current person (main or companion) has already submitted demographics
  bool get _isCurrentPersonDone {
    if (_invitation == null) return false;

    if (_companionIndex == null) {
      // Main guest
      return _invitation?['used'] == true;
    } else {
      // Companion
      final companions = (_invitation?['companions'] as List?) ?? [];
      if (_companionIndex! >= companions.length) return false;
      final companion = companions[_companionIndex!] as Map<String, dynamic>?;
      return companion?['demographicSubmitted'] == true;
    }
  }

  void _setActiveQuestion(String id) {
    if (_activeQuestionId == id) return;
    setState(() => _activeQuestionId = id);
  }

  void _setInvalid(String title, String message) {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _invitation = null;
      _questionSet = null;
      _questions.clear();
      _answers.clear();
      _activeQuestionId = null;
      _invalidTitle = title;
      _invalidMessage = message;
    });
  }

  static String _normalizeType(String type) {
    switch (type) {
      case 'short_answer':
      case 'paragraph':
      case 'multiple_choice':
      case 'checkboxes':
      case 'dropdown':
        return type;
      case 'text':
        return 'short_answer';
      case 'single_choice':
        return 'multiple_choice';
      case 'multi_choice':
        return 'checkboxes';
      default:
        return 'multiple_choice';
    }
  }

  List<List<T>> _chunks<T>(List<T> list, int size) {
    final out = <List<T>>[];
    for (int i = 0; i < list.length; i += size) {
      final end = (i + size > list.length) ? list.length : i + size;
      out.add(List<T>.of(list.sublist(i, end), growable: true)); // ✅ growable
    }
    return out;
  }

  /// Read companion index from URL query parameters
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

  String _readTokenFromUrl() {
    // 1) explicit widget token (if you pass it via router)
    final t1 = widget.token.trim();
    if (t1.isNotEmpty) return t1;

    // 2) normal query param
    final t2 = (Uri.base.queryParameters['token'] ?? '').trim();
    if (t2.isNotEmpty) return t2;

    // 3) hash route support: "#/demographics?invitationId=...&token=..."
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

  int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final s = v.toString().trim();
    return int.tryParse(s) ?? fallback;
  }

  bool _asBool(dynamic v, {bool fallback = false}) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    return null;
  }

  bool _isAnswered(_GuestQuestion q) {
    final v = _answers[q.id];

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

  dynamic _serializeAnswer(dynamic answer) {
    if (answer is String) return answer.trim();
    return answer;
  }

  Future<void> _loadForInvitation(String invitationId) async {
    setState(() {
      _loading = true;
      _invitation = null;
      _questionSet = null;
      _questions.clear();
      _answers.clear();
      _activeInvitationId = invitationId.trim();
      _activeQuestionId = null;
      _invalidTitle = null;
      _invalidMessage = null;
    });

    for (final c in _freeTextCtrls.values) c.dispose();
    for (final c in _textCtrls.values) c.dispose();
    _freeTextCtrls.clear();
    _textCtrls.clear();

    try {
      // -----------------------------
      // 1) Invitation
      // -----------------------------
      final invDoc =
          await _db.collection('invitations').doc(_activeInvitationId).get();

      if (!invDoc.exists) {
        _setInvalid(
          'Invitation not found',
          'This link is invalid. Please request a new invite.',
        );
        return;
      }

      _invitation = invDoc.data();

      // -----------------------------
      // 2) Token + expiry checks
      // -----------------------------
      final tokenFromLink = _readTokenFromUrl();
      final tokenInInvite = (_invitation?['token'] ?? '').toString().trim();

      if (tokenInInvite.isEmpty) {
        _setInvalid(
          'Invitation not found',
          'This link is invalid. Please request a new invite.',
        );
        return;
      }

      final requireToken = !widget.showInvitationInput;
      if (requireToken) {
        if (tokenFromLink.isEmpty) {
          _setInvalid(
            'Invalid link token',
            'This link is missing a token. Please request a new invite.',
          );
          return;
        }
        if (tokenFromLink != tokenInInvite) {
          _setInvalid(
            'Invalid link token',
            'This link token does not match the invitation.',
          );
          return;
        }
      }

      final expires = _asDate(_invitation?['expiresAt']);
      if (expires != null && expires.isBefore(DateTime.now())) {
        _setInvalid(
          'Link expired',
          'This invitation expired on $expires. Please request a new invite.',
        );
        return;
      }

      // -----------------------------
      // 3) Build flow state and check completion status
      // -----------------------------
      final tokenToUse =
          tokenFromLink.isNotEmpty ? tokenFromLink : tokenInInvite;
      _flowState = ResponseFlowState.fromInvitation(
        _invitation!,
        tokenToUse,
        invitationIdOverride: _activeInvitationId, // Use the doc ID we know
      );

      // Get companions list
      final companions = (_invitation?['companions'] as List?) ?? [];

      // Validate companion index if specified
      if (_companionIndex != null) {
        if (_companionIndex! < 0 || _companionIndex! >= companions.length) {
          _setInvalid(
            'Invalid companion',
            'The specified companion does not exist.',
          );
          return;
        }

        // Set current person name for companion
        final companion = companions[_companionIndex!] as Map<String, dynamic>;
        _currentPersonName =
            (companion['name'] ?? 'Companion ${_companionIndex! + 1}')
                .toString();

        // Check if this companion already submitted demographics
        if (companion['demographicSubmitted'] == true) {
          // Already submitted - redirect to next step
          if (!mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToNextStep(tokenToUse);
          });
          return;
        }
      } else {
        // Main guest
        _currentPersonName = (_invitation?['guestName'] ?? 'Guest').toString();

        // Check if main guest already submitted demographics
        if (_asBool(_invitation?['used'], fallback: false)) {
          // Already submitted - redirect to next step
          if (!mounted) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigateToNextStep(tokenToUse);
          });
          return;
        }
      }

      // -----------------------------
      // 4) Check if entire flow is complete
      // -----------------------------
      if (_flowState!.isComplete) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.go(
              '/thank-you?invitationId=${Uri.encodeComponent(_activeInvitationId)}');
        });
        return;
      }

      // -----------------------------
      // 5) Determine questionSetId
      // -----------------------------
      String questionSetId =
          (_invitation?['demographicQuestionSetId'] ?? '').toString().trim();

      // fallback from event (HOST only)
      if (questionSetId.isEmpty) {
        // ✅ Guests must NOT read /events (rules require signed-in)
        if (!widget.showInvitationInput) {
          _setInvalid(
            'Questions not assigned',
            'This invitation is missing a demographic question set. Please ask the host to resend the invite.',
          );
          return;
        }

        final eventId = (_invitation?['eventId'] ?? '').toString().trim();
        if (eventId.isEmpty) {
          _setInvalid(
            'Invitation not found',
            'This link is invalid. Please request a new invite.',
          );
          return;
        }

        final byDoc = await _db.collection('events').doc(eventId).get();
        Map<String, dynamic>? eventData;

        if (byDoc.exists) {
          eventData = byDoc.data();
        } else {
          final q = await _db
              .collection('events')
              .where('eventId', isEqualTo: eventId)
              .limit(1)
              .get();

          if (q.docs.isEmpty) {
            _setInvalid(
              'Invitation not found',
              'This link is invalid. Please request a new invite.',
            );
            return;
          }
          eventData = q.docs.first.data();
        }

        questionSetId = (eventData?['selectedDemographicQuestionSetId'] ?? '')
            .toString()
            .trim();
      }

      if (questionSetId.isEmpty) {
        _setInvalid(
          'Invitation not found',
          'This link is invalid. Please request a new invite.',
        );
        return;
      }

      // -----------------------------
      // 4) Fetch question set
      // -----------------------------
      final qsDoc = await _db
          .collection('demographicQuestionSets')
          .doc(questionSetId)
          .get();

      if (!qsDoc.exists) {
        _setInvalid(
          'Question set not found',
          'This invitation points to a missing question set.',
        );
        return;
      }

      _questionSet = qsDoc.data();

      // -----------------------------
      // 5) Fetch questions (ORDERED by Firestore, no local sort)
      // -----------------------------
      final qSnap = await _db
          .collection('demographicQuestions')
          .where('questionSetId', isEqualTo: questionSetId)
          .where('isDisabled', isEqualTo: false)
          .orderBy('displayOrder') // ✅ Firestore sorts
          .get();

      if (qSnap.docs.isEmpty) {
        if (!mounted) return;
        setState(() {
          _questions.clear();
          _loading = false;
        });
        return;
      }

      final questionDocs = qSnap.docs; // no sorting required
      final questionIds = questionDocs.map((d) => d.id).toList();

      // -----------------------------
      // 6) Fetch options (ORDERED by Firestore, no local sort)
      // -----------------------------
      final Map<String, List<_GuestOption>> optionsByQuestionId = {};

      for (final ids in _chunks(questionIds, 30)) {
        final optSnap = await _db
            .collection('demographicQuestionOptions')
            .where('questionId', whereIn: ids)
            .where('isDisabled', isEqualTo: false)
            .orderBy('displayOrder') // ✅ Firestore sorts
            .get();

        for (final doc in optSnap.docs) {
          final data = doc.data();
          final qId = (data['questionId'] ?? '').toString();
          if (qId.isEmpty) continue;

          final opt = _GuestOption(
            id: doc.id,
            questionId: qId,
            label: (data['label'] ?? '').toString(),
            value: (data['value'] ?? '').toString(),
            requiresFreeText:
                _asBool(data['requiresFreeText'], fallback: false),
            displayOrder: _asInt(data['displayOrder'], fallback: 0),
          );

          optionsByQuestionId.putIfAbsent(qId, () => <_GuestOption>[]).add(opt);
        }
      }

      // -----------------------------
      // 7) Build questions list + init answers/controllers
      //    (options already in displayOrder from query)
      // -----------------------------
      _questions.clear();

      for (final doc in questionDocs) {
        final data = doc.data();
        final qId = doc.id;

        final rawType = (data['questionType'] ?? '').toString();
        final type = _normalizeType(rawType);

        final opts = optionsByQuestionId[qId] ?? <_GuestOption>[];

        final q = _GuestQuestion(
          id: qId,
          text: (data['questionText'] ?? '').toString(),
          type: type,
          isRequired: _asBool(data['isRequired'], fallback: false),
          displayOrder: _asInt(data['displayOrder'], fallback: 0),
          options: opts,
        );

        _questions.add(q);

        if (type == 'short_answer' || type == 'paragraph') {
          _answers[qId] = '';
          _textCtrls[qId] = TextEditingController(text: '');
        } else if (type == 'checkboxes') {
          _answers[qId] = <Map<String, dynamic>>[];
        } else {
          _answers[qId] = null;
        }
      }

      // -----------------------------
      // 8) Final UI state
      // -----------------------------
      if (!mounted) return;
      setState(() {
        _loading = false;
        _activeQuestionId = _questions.isNotEmpty ? _questions.first.id : null;
      });
    } catch (e, st) {
      debugPrint('Demographic load error: $e');
      debugPrint('$st');

      if (!mounted) return;

      _setInvalid(
        'Something went wrong',
        'We could not load the questions right now. Please refresh and try again.',
      );
    }
  }

  // ------------------------------------------------------------
  // ✅ SUBMIT: callable function submitDemographics (prevents resubmit)
  // Now supports companions via companionIndex parameter
  // ------------------------------------------------------------
  Future<void> _submitAndGoNext() async {
    if (_submitting) return;

    final tokenFromLink = (widget.token.isNotEmpty
            ? widget.token
            : (Uri.base.queryParameters['token'] ?? ''))
        .trim();

    final tokenInInvite = (_invitation?['token'] ?? '').toString().trim();

    // Invitation must have token stored
    if (tokenInInvite.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid invitation (missing token)')),
      );
      return;
    }

    // Guests must match token; host demo can skip
    final requireToken = !widget.showInvitationInput;
    if (requireToken && tokenFromLink != tokenInInvite) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid token in link')));
      return;
    }

    // Use link token for guests; for host demo fallback to invitation token
    final tokenToUse = requireToken
        ? tokenFromLink
        : (tokenFromLink.isNotEmpty ? tokenFromLink : tokenInInvite);

    // If current person already submitted demographics, just continue to next step
    if (_isCurrentPersonDone) {
      if (!mounted) return;
      _navigateToNextStep(tokenToUse);
      return;
    }

    // Validate all required questions are answered
    final missing = _questions.where((q) => q.isRequired && !_isAnswered(q));
    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black87,
          content: Text(
            'Please answer all required questions',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final payloadAnswers = _questions.map((q) {
        return <String, dynamic>{
          'questionId': q.id,
          'questionText': q.text,
          'type': q.type,
          'isRequired': q.isRequired,
          'answer': _serializeAnswer(_answers[q.id]),
        };
      }).toList();

      final cf = Get.find<CloudFunctionsService>();
      await cf.submitDemographics(
        invitationId: _activeInvitationId,
        token: tokenToUse,
        answers: payloadAnswers,
        companionIndex:
            _companionIndex, // ✅ Pass companion index (null for main guest)
      );

      // Update local state based on who submitted
      if (_companionIndex == null) {
        // Main guest
        setState(() => _invitation = {...?_invitation, 'used': true});
      } else {
        // Companion - update their status in local state
        final companions = List<Map<String, dynamic>>.from(
          (_invitation?['companions'] as List? ?? [])
              .map((c) => Map<String, dynamic>.from(c as Map)),
        );
        if (_companionIndex! < companions.length) {
          companions[_companionIndex!]['demographicSubmitted'] = true;
          setState(
              () => _invitation = {...?_invitation, 'companions': companions});
        }
      }

      // Rebuild flow state with updated invitation
      _flowState = ResponseFlowState.fromInvitation(_invitation!, tokenToUse);

      if (!mounted) return;

      // Navigate to next step
      _navigateToNextStep(tokenToUse);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Submit failed: ${e.message ?? e.code}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Submit failed: $e',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Navigate to the next step in the flow
  void _navigateToNextStep(String token) {
    // Rebuild flow state from latest invitation data, with invitationId override
    final flowState = ResponseFlowState.fromInvitation(
      _invitation!,
      token,
      invitationIdOverride: _activeInvitationId,
    );
    final nextStep = flowState.getNextStep();
    final nextUrl = nextStep.buildUrl(_activeInvitationId, token);

    debugPrint('Demographics: Navigating to next step: ${nextStep.step}, '
        'companionIndex: ${nextStep.companionIndex}, url: $nextUrl');
    context.go(nextUrl);
  }

  // ------------------------------------------------------------
  // ✅ Styled UI (same layout style as your host screenshot)
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Build dynamic page title based on who is filling
    final String pageTitle;
    final String fillingForLabel;

    if (_companionIndex != null) {
      // Companion - use their actual name
      final name = _currentPersonName.isNotEmpty
          ? _currentPersonName
          : 'Companion ${_companionIndex! + 1}';
      pageTitle = 'Demographics';
      fillingForLabel = 'Filling for: $name';
    } else {
      // Main guest
      pageTitle = 'Demographics';
      fillingForLabel = 'Filling for: You';
    }

    final title = (_questionSet?['title'] ?? pageTitle).toString();
    final description = (_questionSet?['description'] ?? '').toString();

    final content = LayoutBuilder(
      builder: (ctx, constraints) {
        final viewportH = MediaQuery.of(ctx).size.height;
        final boundedH = constraints.hasBoundedHeight;
        final maxH = boundedH ? constraints.maxHeight : viewportH;

        final scrollH = (maxH - 280).clamp(260.0, 800.0);

        return SizedBox(
          width: double.infinity,
          height: boundedH ? maxH : null,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: gfBackground)),
              Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Progress indicator - show when there are companions
                            if (_invitation != null &&
                                ((_invitation?['companions'] as List?) ?? [])
                                    .isNotEmpty) ...[
                              _buildProgressBanner(fillingForLabel),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              pageTitle,
                              style: GoogleFonts.poppins(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (widget.showInvitationInput) ...[
                              _InvitationLoaderCard(
                                controller: _invitationIdCtrl,
                                loading: _loading || _submitting,
                                onLoad: () {
                                  final id = _invitationIdCtrl.text.trim();
                                  if (id.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.black87,
                                        content: Text(
                                          'Please paste invitationId',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  _loadForInvitation(id);
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            _HeaderWithAction(
                              title: title,
                              description: description,
                              actionLabel:
                                  _isCurrentPersonDone ? 'Continue' : 'Next',
                              actionEnabled: !_loading &&
                                  !_submitting &&
                                  _invitation != null &&
                                  (_isCurrentPersonDone ||
                                      _questions
                                          .isNotEmpty), // ✅ allow Continue even if questions empty
                              onAction: _submitAndGoNext,
                            ),
                            const SizedBox(height: 14),
                            if (!_loading &&
                                _invitation != null &&
                                !_isCurrentPersonDone)
                              Center(
                                child: Text(
                                  'Click on a question to answer',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: scrollH,
                              child: _buildScrollableBody(),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_submitting)
                Positioned.fill(
                  child: Container(
                    color: gfBackground.withOpacity(0.35),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: kGfPurple,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    // Return content directly - ShellRoute provides GuestPageWrapper
    return content;
  }

  /// Build a progress banner showing which person is being filled
  Widget _buildProgressBanner(String fillingForLabel) {
    final companions = (_invitation?['companions'] as List?) ?? [];
    final totalPeople = 1 + companions.length; // main guest + companions

    // Calculate how many demographics are complete
    int completedCount = 0;
    if (_asBool(_invitation?['used'], fallback: false)) completedCount++;
    for (final c in companions) {
      if ((c as Map)['demographicSubmitted'] == true) completedCount++;
    }

    // Current person number (1-based)
    final currentPersonNum =
        _companionIndex == null ? 1 : (_companionIndex! + 2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kGfPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kGfPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.people_outline, color: kGfPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fillingForLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kGfPurple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Person $currentPersonNum of $totalPeople • $completedCount completed',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: kTextBody,
                  ),
                ),
              ],
            ),
          ),
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kGfPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$completedCount / $totalPeople',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 3, color: kGfPurple),
      );
    }

    if (_invitation == null && _activeInvitationId.isEmpty) {
      return const _InfoCard(
        icon: Icons.info_outline_rounded,
        iconColor: kGfPurple,
        title: 'Waiting for invitation',
        message: 'Paste an invitationId above and click Load.',
      );
    }

    if (_invitation == null) {
      return _InfoCard(
        icon: Icons.error_outline_rounded,
        iconColor: Colors.red.shade600,
        title: _invalidTitle ?? 'Invalid or expired invitation',
        message: _invalidMessage ?? 'Please check your link and try again.',
      );
    }

    // Check if current person (main or companion) already submitted
    if (_isCurrentPersonDone) {
      final name =
          _companionIndex == null ? 'Your' : '${_currentPersonName}\'s';
      return _InfoCard(
        icon: Icons.check_circle_outline_rounded,
        iconColor: Colors.green,
        title: 'Already submitted',
        message:
            '$name responses were already submitted. Click Continue to proceed.',
      );
    }

    if (_questions.isEmpty) {
      return const _InfoCard(
        icon: Icons.help_outline_rounded,
        iconColor: kGfPurple,
        title: 'No questions in this set',
        message: 'There are no demographic questions to answer.',
      );
    }

    return Scrollbar(
      controller: _listCtrl,
      thumbVisibility: true,
      child: ListView.builder(
        controller: _listCtrl,
        padding: EdgeInsets.zero,
        itemCount: _questions.length,
        itemBuilder: (_, idx) {
          final q = _questions[idx];
          final isActive = q.id == _activeQuestionId;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GuestGoogleFormsQuestionCard(
              question: q,
              isActive: isActive,
              answer: _answers[q.id],
              textController: _textCtrls[q.id],
              freeTextCtrls: _freeTextCtrls,
              onTap: () => _setActiveQuestion(q.id),
              onAnswerChanged: (value) =>
                  setState(() => _answers[q.id] = value),
            ),
          );
        },
      ),
    );
  }
}

// ------------------------------------------------------------
// Header card + Finish button (exact style)
// ------------------------------------------------------------
class _HeaderWithAction extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final bool actionEnabled;
  final VoidCallback onAction;

  const _HeaderWithAction({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.actionEnabled,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final safeTitle = title.trim().isEmpty ? 'Untitled form' : title.trim();
    final safeDesc = description.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
            color: Colors.white,
            elevation: 3,
            shadowColor: Colors.black.withOpacity(0.08),
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: kBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 6,
                  decoration: const BoxDecoration(
                    color: kGfPurple,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        safeTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: kTextDark,
                        ),
                      ),
                      if (safeDesc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          safeDesc,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kTextDark,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: actionEnabled ? onAction : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kGfPurple,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// Invitation loader card (host demo only)
// ------------------------------------------------------------
class _InvitationLoaderCard extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onLoad;

  const _InvitationLoaderCard({
    required this.controller,
    required this.loading,
    required this.onLoad,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kBorder),
      ),
      child: Column(
        children: [
          Container(
            height: 6,
            decoration: const BoxDecoration(
              color: kGfPurple,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Paste invitationId',
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: kAccent, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: loading ? null : onLoad,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGfPurple,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Load'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// Models
// ------------------------------------------------------------
class _GuestQuestion {
  final String id;
  final String text;
  final String type;
  final bool isRequired;
  final int displayOrder;
  final List<_GuestOption> options;

  const _GuestQuestion({
    required this.id,
    required this.text,
    required this.type,
    required this.isRequired,
    required this.displayOrder,
    required this.options,
  });
}

class _GuestOption {
  final String id;
  final String questionId;
  final String label;
  final String value;
  final bool requiresFreeText;
  final int displayOrder;

  const _GuestOption({
    required this.id,
    required this.questionId,
    required this.label,
    required this.value,
    required this.requiresFreeText,
    required this.displayOrder,
  });
}

// ------------------------------------------------------------
// Info card
// ------------------------------------------------------------
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: iconColor),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kTextBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Question card (Google Forms style)
// ------------------------------------------------------------
class _GuestGoogleFormsQuestionCard extends StatelessWidget {
  final _GuestQuestion question;
  final bool isActive;
  final dynamic answer;

  final TextEditingController? textController;
  final Map<String, TextEditingController> freeTextCtrls;

  final VoidCallback onTap;
  final ValueChanged<dynamic> onAnswerChanged;

  const _GuestGoogleFormsQuestionCard({
    required this.question,
    required this.isActive,
    required this.answer,
    required this.textController,
    required this.freeTextCtrls,
    required this.onTap,
    required this.onAnswerChanged,
  });

  // -----------------------------
  // Helpers (optionId based)
  // -----------------------------

  /// Returns selected optionId for single-choice/dropdown.
  /// Supports:
  /// - String => optionId (new) OR opt.value (legacy)
  /// - Map => { optionId: ... } (new) OR { value: ... } (legacy)
  String? _selectedOptionId() {
    if (answer is String) {
      final s = (answer as String).trim();
      if (s.isEmpty) return null;

      // New: stored as optionId
      if (question.options.any((o) => o.id == s)) return s;

      // Legacy: stored as opt.value -> convert to optionId
      final byValue = question.options.where((o) => o.value == s);
      if (byValue.isNotEmpty) return byValue.first.id;

      return null;
    }

    if (answer is Map) {
      final m = answer as Map;

      final optId = (m['optionId'] ?? '').toString().trim();
      if (optId.isNotEmpty && question.options.any((o) => o.id == optId)) {
        return optId;
      }

      final legacyVal = (m['value'] ?? '').toString().trim();
      if (legacyVal.isNotEmpty) {
        final byValue = question.options.where((o) => o.value == legacyVal);
        if (byValue.isNotEmpty) return byValue.first.id;
      }
    }

    return null;
  }

  /// Returns selected checkbox items as list of maps.
  /// Supports legacy entries that had "value" instead of "optionId".
  List<Map<String, dynamic>> _selectedCheckboxItems() {
    if (answer is! List) return <Map<String, dynamic>>[];

    final out = <Map<String, dynamic>>[];
    for (final item in (answer as List)) {
      if (item is Map) {
        out.add(Map<String, dynamic>.from(item as Map));
      } else if (item is String) {
        // Accept list of optionIds (or legacy values) as strings
        out.add({'optionId': item});
      }
    }
    return out;
  }

  bool _isChecked(_GuestOption opt, List<Map<String, dynamic>> selected) {
    return selected.any((x) {
      final optId = (x['optionId'] ?? '').toString().trim();
      if (optId.isNotEmpty) {
        if (optId == opt.id) return true;

        // Legacy: if stored as value string in optionId slot
        if (optId == opt.value) return true;
      }

      // Legacy: old key
      final legacyVal = (x['value'] ?? '').toString().trim();
      return legacyVal.isNotEmpty && legacyVal == opt.value;
    });
  }

  // -----------------------------
  // UI
  // -----------------------------

  @override
  Widget build(BuildContext context) {
    final titleText =
        question.isRequired ? '${question.text} *' : question.text;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? kAccent : kBorder,
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isActive ? 0.08 : 0.04),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 20,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              titleText,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    switch (question.type) {
      case 'short_answer':
      case 'paragraph':
        return TextField(
          controller: textController,
          enabled: isActive,
          maxLines: question.type == 'paragraph' ? 4 : 1,
          onChanged: (v) => onAnswerChanged(v),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kTextDark,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kAccent, width: 2),
            ),
          ),
        );

      case 'dropdown':
        final selectedId = _selectedOptionId();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedId,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kAccent, width: 2),
                ),
              ),
              hint: Text(
                'Choose an option',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              items: [
                for (final opt in question.options)
                  DropdownMenuItem(
                    value: opt.id, // ✅ optionId
                    child: Text(
                      opt.label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextDark,
                      ),
                    ),
                  ),
              ],
              onChanged: !isActive
                  ? null
                  : (optId) {
                      if (optId == null) {
                        onAnswerChanged(null);
                        return;
                      }
                      final opt =
                          question.options.firstWhere((o) => o.id == optId);

                      if (opt.requiresFreeText) {
                        final ctrlKey = '${question.id}__${opt.id}';
                        freeTextCtrls.putIfAbsent(
                            ctrlKey, () => TextEditingController());

                        onAnswerChanged({
                          'optionId': opt.id, // ✅ rule matching
                          'value': opt.value, // optional legacy/debug
                          'label': opt.label,
                          'requiresFreeText': true,
                          'freeText': freeTextCtrls[ctrlKey]!.text,
                        });
                      } else {
                        onAnswerChanged(opt.id); // ✅ simplest
                      }
                    },
            ),
            const SizedBox(height: 8),
            _maybeFreeTextForSingleChoice(),
          ],
        );

      case 'checkboxes':
        final selected = _selectedCheckboxItems();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final opt in question.options) _checkboxRow(opt, selected),
          ],
        );

      case 'multiple_choice':
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final opt in question.options) _radioRow(opt),
            _maybeFreeTextForSingleChoice(),
          ],
        );
    }
  }

  Widget _radioRow(_GuestOption opt) {
    final selectedId = _selectedOptionId();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Radio<String>(
              value: opt.id, // ✅ optionId
              groupValue: selectedId,
              onChanged: !isActive
                  ? null
                  : (v) {
                      if (v == null) return;

                      if (opt.requiresFreeText) {
                        final ctrlKey = '${question.id}__${opt.id}';
                        freeTextCtrls.putIfAbsent(
                            ctrlKey, () => TextEditingController());

                        onAnswerChanged({
                          'optionId': opt.id, // ✅ rule matching
                          'value': opt.value,
                          'label': opt.label,
                          'requiresFreeText': true,
                          'freeText': freeTextCtrls[ctrlKey]!.text,
                        });
                      } else {
                        onAnswerChanged(opt.id); // ✅ simplest
                      }
                    },
              activeColor: kAccent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Expanded(
            child: Text(
              opt.label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkboxRow(_GuestOption opt, List<Map<String, dynamic>> selected) {
    final isChecked = _isChecked(opt, selected);
    final ctrlKey = '${question.id}__${opt.id}';

    if (opt.requiresFreeText) {
      freeTextCtrls.putIfAbsent(ctrlKey, () => TextEditingController());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: isChecked,
                  onChanged: !isActive
                      ? null
                      : (v) {
                          final next =
                              List<Map<String, dynamic>>.from(selected);

                          if (v == true) {
                            if (opt.requiresFreeText) {
                              next.add({
                                'optionId': opt.id, // ✅ rule matching
                                'value': opt.value,
                                'label': opt.label,
                                'requiresFreeText': true,
                                'freeText': freeTextCtrls[ctrlKey]!.text,
                              });
                            } else {
                              next.add({
                                'optionId': opt.id, // ✅ rule matching
                                'value': opt.value,
                                'label': opt.label,
                              });
                            }
                          } else {
                            next.removeWhere((x) {
                              final oid =
                                  (x['optionId'] ?? '').toString().trim();
                              if (oid.isNotEmpty) {
                                // normal remove by optionId
                                if (oid == opt.id) return true;

                                // legacy: stored as opt.value in optionId slot
                                if (oid == opt.value) return true;
                              }

                              // legacy remove by value
                              final legacyVal =
                                  (x['value'] ?? '').toString().trim();
                              return legacyVal.isNotEmpty &&
                                  legacyVal == opt.value;
                            });
                          }

                          onAnswerChanged(next);
                        },
                  activeColor: kAccent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Expanded(
                child: Text(
                  opt.label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: kTextDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (opt.requiresFreeText && isChecked)
          Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 10),
            child: TextField(
              controller: freeTextCtrls[ctrlKey],
              enabled: isActive,
              decoration: InputDecoration(
                labelText: 'Please specify',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kAccent, width: 2),
                ),
              ),
              onChanged: (txt) {
                final next = List<Map<String, dynamic>>.from(selected);
                final idx = next.indexWhere((x) {
                  final oid = (x['optionId'] ?? '').toString().trim();
                  if (oid.isNotEmpty) return oid == opt.id || oid == opt.value;

                  final legacyVal = (x['value'] ?? '').toString().trim();
                  return legacyVal.isNotEmpty && legacyVal == opt.value;
                });

                if (idx >= 0) {
                  next[idx] = {
                    ...next[idx],
                    'optionId': opt.id,
                    'requiresFreeText': true,
                    'freeText': txt,
                  };
                  onAnswerChanged(next);
                }
              },
            ),
          ),
      ],
    );
  }

  Widget _maybeFreeTextForSingleChoice() {
    if (answer is! Map) return const SizedBox.shrink();
    final a = answer as Map;
    if (a['requiresFreeText'] != true) return const SizedBox.shrink();

    final optId = (a['optionId'] ?? '').toString().trim();
    if (optId.isEmpty) return const SizedBox.shrink();

    final ctrlKey = '${question.id}__${optId}';
    freeTextCtrls.putIfAbsent(
      ctrlKey,
      () => TextEditingController(text: (a['freeText'] ?? '').toString()),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 8),
      child: TextField(
        controller: freeTextCtrls[ctrlKey],
        enabled: isActive,
        decoration: InputDecoration(
          labelText: 'Please specify',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kAccent, width: 2),
          ),
        ),
        onChanged: (txt) => onAnswerChanged({...a, 'freeText': txt}),
      ),
    );
  }
}
