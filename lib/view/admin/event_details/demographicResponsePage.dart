import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DemographicResponsePage extends StatefulWidget {
  final String invitationId;

  /// When true, shows an input to paste invitationId + Load (for sidebar demo).
  final bool showInvitationInput;
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

  Map<String, dynamic>? _invitation;
  Map<String, dynamic>? _questionSet;

  final List<_GuestQuestion> _questions = [];
  final Map<String, dynamic> _answers = {}; // questionId -> dynamic
  final Map<String, TextEditingController> _freeTextCtrls = {}; // for "other"
  final Map<String, TextEditingController> _textCtrls = {}; // short/paragraph

  late final TextEditingController _invitationIdCtrl;

  @override
  void initState() {
    super.initState();
    _invitationIdCtrl = TextEditingController(text: widget.invitationId);

    final initial = widget.invitationId.trim();
    if (initial.isEmpty) {
      // Sidebar demo: open page first, paste invitationId, then load.
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
    for (final c in _freeTextCtrls.values) {
      c.dispose();
    }
    for (final c in _textCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadForInvitation(String invitationId) async {
    setState(() {
      _loading = true;
      _invitation = null;
      _questionSet = null;
      _questions.clear();
      _answers.clear();
      _activeInvitationId = invitationId.trim();
    });

    // cleanup controllers for previous load
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

      // Token validation:
      // - If token exists in URL, it must match.
      // - If token is NOT in URL (sidebar demo), we allow it.
      final uri = Uri.base;
      final tokenFromLink = uri.queryParameters['token']; // may be null
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

        // Try doc(eventId) first; fallback to where('eventId' == eventId)
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

      // Fetch question set (for title/description)
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

      // Build question list + init answers
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
      setState(() => _loading = false);
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
        const SnackBar(content: Text('Please answer all required questions')),
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

      // This will fail with your current rules (invitations write=false), so keep it optional.
      try {
        await _db.collection('invitations').doc(_activeInvitationId).update({
          'used': true,
          'usedAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      if (!mounted) return;

      _invitationIdCtrl.clear();
      await showDialog<void>(
        context: context,
        useRootNavigator: false, // ✅ important in ShellRoute
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Thanks'),
          content: const Text('Your responses are submitted'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogCtx).pop(), // ✅ pop dialog correctly
              child: const Text('OK'),
            ),
          ],
        ),
      );

      if (!mounted) return;

      if (widget.showInvitationInput) {
        // Dispose old controllers to avoid leaks
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
        });
        _invitationIdCtrl.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        (_questionSet?['title'] ?? 'Demographic Questions').toString();
    final description = (_questionSet?['description'] ?? '').toString();

    final pageBody = Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ✅ In host-demo mode: paste invitationId + load
            if (widget.showInvitationInput) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _invitationIdCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Paste invitationId',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        final id = _invitationIdCtrl.text.trim();
                        if (id.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Please paste invitationId')),
                          );
                          return;
                        }
                        _loadForInvitation(id);
                      },
                      child: const Text('Load'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            if (_loading) ...[
              const SizedBox(height: 40),
              const Center(child: CircularProgressIndicator()),
            ] else if (_invitation == null && _activeInvitationId.isEmpty) ...[
              // ✅ first time open from sidebar
              const SizedBox(height: 20),
              const Text('Paste an invitationId above and click Load.'),
            ] else if (_invitation == null) ...[
              const SizedBox(height: 20),
              const Text('Invalid or expired invitation'),
            ] else ...[
              if (description.trim().isNotEmpty) ...[
                Text(description,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 12),
              ],
              if (_questions.isEmpty)
                const Text('No questions in this set')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _questions.length,
                  itemBuilder: (_, idx) {
                    final q = _questions[idx];
                    return _QuestionCard(
                      question: q,
                      answer: _answers[q.id],
                      textController: _textCtrls[q.id],
                      freeTextCtrls: _freeTextCtrls,
                      onAnswerChanged: (value) {
                        setState(() => _answers[q.id] = value);
                      },
                    );
                  },
                ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Finish'),
              ),
            ],
          ],
        ),
      ),
    );

    // ✅ If embedded inside ContentWrapper: DO NOT return Scaffold
    if (widget.embedded) return pageBody;

    // ✅ For public /demographics route: return Scaffold
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: pageBody,
    );
  }
}

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

class _QuestionCard extends StatelessWidget {
  final _GuestQuestion question;
  final dynamic answer;

  final TextEditingController? textController;
  final Map<String, TextEditingController> freeTextCtrls;

  final ValueChanged<dynamic> onAnswerChanged;

  const _QuestionCard({
    required this.question,
    required this.answer,
    required this.textController,
    required this.freeTextCtrls,
    required this.onAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    final title = question.isRequired ? '${question.text} *' : question.text;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
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
          maxLines: question.type == 'paragraph' ? 4 : 1,
          onChanged: (v) => onAnswerChanged(v),
          decoration: const InputDecoration(border: OutlineInputBorder()),
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
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                for (final opt in question.options)
                  DropdownMenuItem(value: opt.value, child: Text(opt.label)),
              ],
              onChanged: (v) {
                if (v == null) {
                  onAnswerChanged(null);
                  return;
                }
                final opt = question.options.firstWhere((o) => o.value == v);
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
          children: [
            for (final opt in question.options) _checkboxRow(opt, selected),
          ],
        );

      case 'multiple_choice':
      default:
        final selected =
            (answer is Map) ? (answer['value'] as String?) : answer as String?;
        return Column(
          children: [
            for (final opt in question.options)
              RadioListTile<String>(
                value: opt.value,
                groupValue: selected,
                title: Text(opt.label),
                onChanged: (v) {
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
              ),
            _maybeFreeTextForSingleChoice(),
          ],
        );
    }
  }

  Widget _checkboxRow(_GuestOption opt, List<Map<String, dynamic>> selected) {
    final isChecked = selected.any((x) => x['value'] == opt.value);
    final ctrlKey = '${question.id}__${opt.value}';
    if (opt.requiresFreeText) {
      freeTextCtrls.putIfAbsent(ctrlKey, () => TextEditingController());
    }

    return Column(
      children: [
        CheckboxListTile(
          value: isChecked,
          title: Text(opt.label),
          onChanged: (v) {
            final next = List<Map<String, dynamic>>.from(selected);

            if (v == true) {
              if (opt.requiresFreeText) {
                next.add({
                  'value': opt.value,
                  'label': opt.label,
                  'requiresFreeText': true,
                  'freeText': freeTextCtrls[ctrlKey]!.text,
                });
              } else {
                next.add({'value': opt.value, 'label': opt.label});
              }
            } else {
              next.removeWhere((x) => x['value'] == opt.value);
            }
            onAnswerChanged(next);
          },
        ),
        if (opt.requiresFreeText && isChecked)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
            child: TextField(
              controller: freeTextCtrls[ctrlKey],
              decoration: const InputDecoration(
                labelText: 'Please specify',
                border: OutlineInputBorder(),
              ),
              onChanged: (txt) {
                final next = List<Map<String, dynamic>>.from(selected);
                final idx = next.indexWhere((x) => x['value'] == opt.value);
                if (idx >= 0) {
                  next[idx] = {
                    ...next[idx],
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

    final value = (a['value'] ?? '').toString();
    if (value.isEmpty) return const SizedBox.shrink();

    final ctrlKey = '${question.id}__$value';
    freeTextCtrls.putIfAbsent(
      ctrlKey,
      () => TextEditingController(text: (a['freeText'] ?? '').toString()),
    );

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
      child: TextField(
        controller: freeTextCtrls[ctrlKey],
        decoration: const InputDecoration(
          labelText: 'Please specify',
          border: OutlineInputBorder(),
        ),
        onChanged: (txt) {
          onAnswerChanged({
            ...a,
            'freeText': txt,
          });
        },
      ),
    );
  }
}
