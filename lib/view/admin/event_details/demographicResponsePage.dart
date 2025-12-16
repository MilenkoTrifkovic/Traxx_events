import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ✅ Same palette used in HostQuestionsScreen
const Color kAccent = Color(0xFF6C4BFF);
const Color kBorder = Color(0xFFE5E5E5);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextBody = Color(0xFF333333);
const Color kGfPurple = Color(0xFF673AB7);
const Color _gfBackground = Color(0xFFF4F0FB);

class DemographicResponsePage extends StatefulWidget {
  final String invitationId;

  /// When true, shows an input to paste invitationId + Load (for sidebar demo).
  final bool showInvitationInput;

  /// When true, this widget is embedded inside another wrapper; do not return Scaffold.
  final bool embedded;

  const DemographicResponsePage({
    super.key,
    required this.invitationId,
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

  Map<String, dynamic>? _invitation;
  Map<String, dynamic>? _questionSet;

  final List<_GuestQuestion> _questions = [];
  final Map<String, dynamic> _answers = {}; // questionId -> dynamic
  final Map<String, TextEditingController> _freeTextCtrls = {}; // for "other"
  final Map<String, TextEditingController> _textCtrls = {}; // short/paragraph

  late final TextEditingController _invitationIdCtrl;
  final ScrollController _listCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _invitationIdCtrl = TextEditingController(text: widget.invitationId);

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

  void _setActiveQuestion(String id) {
    if (_activeQuestionId == id) return;
    setState(() => _activeQuestionId = id);
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
    });

    for (final c in _freeTextCtrls.values) c.dispose();
    for (final c in _textCtrls.values) c.dispose();
    _freeTextCtrls.clear();
    _textCtrls.clear();

    try {
      final invDoc =
          await _db.collection('invitations').doc(_activeInvitationId).get();

      if (!invDoc.exists) {
        _setInvalid();
        return;
      }

      _invitation = invDoc.data();

      // Token validation (web links)
      final uri = Uri.base;
      final tokenFromLink = uri.queryParameters['token'];
      final tokenInInvite = _invitation?['token'];

      if (tokenFromLink != null &&
          tokenInInvite != null &&
          tokenFromLink != tokenInInvite) {
        _setInvalid();
        return;
      }

      // expiry
      final expiresTimestamp = _invitation?['expiresAt'] as Timestamp?;
      final expires = expiresTimestamp?.toDate();
      if (expires != null && expires.isBefore(DateTime.now())) {
        _setInvalid();
        return;
      }

      // used
      if (_invitation?['used'] == true) {
        _setInvalid();
        return;
      }

      // Determine setId
      String? questionSetId =
          _invitation?['demographicQuestionSetId'] as String?;

      // Fallback: fetch from event if not present in invitation
      if (questionSetId == null || questionSetId.isEmpty) {
        final eventId = _invitation?['eventId'] as String?;
        if (eventId == null || eventId.isEmpty) {
          _setInvalid();
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
            _setInvalid();
            return;
          }
          eventData = q.docs.first.data();
        }

        questionSetId =
            eventData?['selectedDemographicQuestionSetId'] as String?;
      }

      if (questionSetId == null || questionSetId.isEmpty) {
        _setInvalid();
        return;
      }

      // Fetch question set
      final qsDoc = await _db
          .collection('demographicQuestionSets')
          .doc(questionSetId)
          .get();
      if (!qsDoc.exists) {
        _setInvalid();
        return;
      }
      _questionSet = qsDoc.data();

      // Fetch questions
      final qSnap = await _db
          .collection('demographicQuestions')
          .where('isDisabled', isEqualTo: false)
          .where('questionSetId', isEqualTo: questionSetId)
          .orderBy('displayOrder')
          .get();

      if (qSnap.docs.isEmpty) {
        if (!mounted) return;
        setState(() {
          _questions.clear();
          _loading = false;
        });
        return;
      }

      final questionDocs = qSnap.docs;
      final questionIds = questionDocs.map((d) => d.id).toList();

      // Fetch options for all questionIds (chunked whereIn, max 30)
      final Map<String, List<_GuestOption>> optionsByQuestionId = {};
      for (final chunk in _chunks(questionIds, 30)) {
        final optSnap = await _db
            .collection('demographicQuestionOptions')
            .where('isDisabled', isEqualTo: false)
            .where('questionId', whereIn: chunk)
            .get();

        for (final doc in optSnap.docs) {
          final data = doc.data();
          final qId = (data['questionId'] ?? '') as String;
          if (qId.isEmpty) continue;

          final opt = _GuestOption(
            id: doc.id,
            questionId: qId,
            label: (data['label'] ?? '').toString(),
            value: (data['value'] ?? '').toString(),
            requiresFreeText: (data['requiresFreeText'] ?? false) == true,
            displayOrder: (data['displayOrder'] ?? 0) as int,
          );

          optionsByQuestionId.putIfAbsent(qId, () => []).add(opt);
        }
      }

      _questions.clear();
      for (final doc in questionDocs) {
        final data = doc.data();
        final qId = doc.id;

        final rawType = (data['questionType'] ?? '').toString();
        final type = _normalizeType(rawType);

        final q = _GuestQuestion(
          id: qId,
          text: (data['questionText'] ?? '').toString(),
          type: type,
          isRequired: (data['isRequired'] ?? false) == true,
          displayOrder: (data['displayOrder'] ?? 0) as int,
          options: (optionsByQuestionId[qId] ?? const [])
            ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
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

      if (!mounted) return;
      setState(() {
        _loading = false;
        _activeQuestionId = _questions.isNotEmpty ? _questions.first.id : null;
      });
    } catch (_) {
      _setInvalid();
    }
  }

  void _setInvalid() {
    if (!mounted) return;
    setState(() {
      _loading = false;
      _invitation = null;
      _questionSet = null;
      _questions.clear();
      _answers.clear();
      _activeQuestionId = null;
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
      out.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return out;
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

  Future<void> _submit() async {
    if (_submitting) return;

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
      final inv = _invitation!;
      final eventId = (inv['eventId'] ?? '').toString();
      final orgId = (inv['organisationId'] ?? '').toString();

      final payloadAnswers = _questions.map((q) {
        return {
          'questionId': q.id,
          'questionText': q.text,
          'type': q.type,
          'isRequired': q.isRequired,
          'answer': _serializeAnswer(_answers[q.id]),
        };
      }).toList();

      await _db.collection('demographicQuestionsResponses').add({
        'eventId': eventId,
        'organisationId': orgId,
        'invitationId': _activeInvitationId,
        'guestId': inv['guestId'],
        'guestEmail': inv['guestEmail'],
        'demographicQuestionSetId':
            inv['demographicQuestionSetId'] ?? inv['questionSetId'],
        'answers': payloadAnswers,
        'createdAt': FieldValue.serverTimestamp(),
      });

      try {
        await _db.collection('invitations').doc(_activeInvitationId).update({
          'used': true,
          'usedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        useRootNavigator: false,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          title: Text('Thanks',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Text('Your responses are submitted',
              style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'OK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: kGfPurple,
                ),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (widget.showInvitationInput) {
        for (final c in _freeTextCtrls.values) c.dispose();
        for (final c in _textCtrls.values) c.dispose();
        _freeTextCtrls.clear();
        _textCtrls.clear();

        setState(() {
          _activeInvitationId = '';
          _invitation = null;
          _questionSet = null;
          _questions.clear();
          _answers.clear();
          _loading = false;
          _activeQuestionId = null;
        });
        _invitationIdCtrl.clear();
      }
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

  @override
  Widget build(BuildContext context) {
    // ✅ Big top heading like other host pages
    const pageTitle = 'Demographic Questions';

    final title = (_questionSet?['title'] ?? pageTitle).toString();
    final description = (_questionSet?['description'] ?? '').toString();

    final content = LayoutBuilder(
      builder: (ctx, constraints) {
        final viewportH = MediaQuery.of(ctx).size.height;
        final boundedH = constraints.hasBoundedHeight;
        final maxH = boundedH ? constraints.maxHeight : viewportH;

        // Header area height approx (title + cards). We keep a safe scroll height.
        final scrollH = (maxH - 280).clamp(260.0, 800.0);

        return SizedBox(
          width: double.infinity,
          height: boundedH ? maxH : null,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: _gfBackground)),
              Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  // ✅ only this outer scroll is for small screens;
                  // the questions list still scrolls independently.
                  physics: const ClampingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ✅ BIG BLACK HEADING (matches your other host page)
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
                              actionLabel: 'Finish',
                              actionEnabled: !_loading &&
                                  !_submitting &&
                                  _invitation != null &&
                                  _questions.isNotEmpty,
                              onAction: _submit,
                            ),

                            const SizedBox(height: 14),
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

                            // ✅ ONLY THIS AREA SCROLLS (like HostQuestionsScreen)
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
                    color: _gfBackground.withOpacity(0.35),
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

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: _gfBackground,
      body: content,
    );
  }

  Widget _buildScrollableBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: kGfPurple,
        ),
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
        title: 'Invalid or expired invitation',
        message: 'Please check your link and try again.',
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

// -----------------------------------------------------------------------------
// Header + Finish button
// -----------------------------------------------------------------------------

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
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(12)),
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

// -----------------------------------------------------------------------------
// Invitation loader (host-demo)
// -----------------------------------------------------------------------------

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
                          horizontal: 12, vertical: 12),
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

// -----------------------------------------------------------------------------
// Models
// -----------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------
// Info card
// -----------------------------------------------------------------------------

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

// -----------------------------------------------------------------------------
// Question card
// -----------------------------------------------------------------------------

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

  String _typeLabel(String t) {
    switch (t) {
      case 'short_answer':
        return 'Short answer';
      case 'paragraph':
        return 'Paragraph';
      case 'checkboxes':
        return 'Checkboxes';
      case 'dropdown':
        return 'Dropdown';
      case 'multiple_choice':
      default:
        return 'Multiple choice';
    }
  }

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    titleText,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: kTextDark,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 200,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                    ),
                    child: Text(
                      _typeLabel(question.type),
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: kTextBody,
                      ),
                    ),
                  ),
                ),
              ],
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
        final selected = (answer is Map)
            ? (answer['value'] as String?)
            : (answer as String?);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selected,
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
                    value: opt.value,
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
                  : (v) {
                      if (v == null) {
                        onAnswerChanged(null);
                        return;
                      }
                      final opt =
                          question.options.firstWhere((o) => o.value == v);
                      if (opt.requiresFreeText) {
                        final ctrlKey = '${question.id}__${opt.value}';
                        freeTextCtrls.putIfAbsent(
                            ctrlKey, () => TextEditingController());
                        onAnswerChanged({
                          'value': opt.value,
                          'label': opt.label,
                          'requiresFreeText': true,
                          'freeText': freeTextCtrls[ctrlKey]!.text,
                        });
                      } else {
                        onAnswerChanged(opt.value);
                      }
                    },
            ),
            const SizedBox(height: 8),
            _maybeFreeTextForSingleChoice(),
          ],
        );

      case 'checkboxes':
        final selected = (answer as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];
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
    final selected =
        (answer is Map) ? (answer['value'] as String?) : answer as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Radio<String>(
              value: opt.value,
              groupValue: selected,
              onChanged: !isActive
                  ? null
                  : (v) {
                      if (v == null) return;
                      if (opt.requiresFreeText) {
                        final ctrlKey = '${question.id}__${opt.value}';
                        freeTextCtrls.putIfAbsent(
                            ctrlKey, () => TextEditingController());
                        onAnswerChanged({
                          'value': opt.value,
                          'label': opt.label,
                          'requiresFreeText': true,
                          'freeText': freeTextCtrls[ctrlKey]!.text,
                        });
                      } else {
                        onAnswerChanged(opt.value);
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
    final isChecked = selected.any((x) => x['value'] == opt.value);
    final ctrlKey = '${question.id}__${opt.value}';
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
                                'value': opt.value,
                                'label': opt.label,
                                'requiresFreeText': true,
                                'freeText': freeTextCtrls[ctrlKey]!.text,
                              });
                            } else {
                              next.add(
                                  {'value': opt.value, 'label': opt.label});
                            }
                          } else {
                            next.removeWhere((x) => x['value'] == opt.value);
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
                final idx = next.indexWhere((x) => x['value'] == opt.value);
                if (idx >= 0) {
                  next[idx] = {
                    ...next[idx],
                    'requiresFreeText': true,
                    'freeText': txt
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

    final value = (a['value'] ?? '').toString();
    if (value.isEmpty) return const SizedBox.shrink();

    final ctrlKey = '${question.id}__$value';
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
        onChanged: (txt) {
          onAnswerChanged({...a, 'freeText': txt});
        },
      ),
    );
  }
}
