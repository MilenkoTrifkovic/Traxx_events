// QuestionRulesScreen.dart
//
// ✅ Neat, clean, Poppins-based UI (NOT Google-Forms look, NO lavender background)
// ✅ Add/Delete conditional (sub) questions based on a selected answer option
// ✅ Table view of existing rules for a selected Question Set
//
// NOTE:
// - This screen is intentionally self-contained (does not depend on HostQuestionsController models)
// - It reads/writes Firestore directly so it will work even before you update your existing models.
// - Adjust imports/paths as needed for your project structure.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestionRulesScreen extends StatefulWidget {
  const QuestionRulesScreen({super.key});

  @override
  State<QuestionRulesScreen> createState() => _QuestionRulesScreenState();
}

class _QuestionRulesScreenState extends State<QuestionRulesScreen> {
  // ---------------------------------------------------------------------------
  // Styling (clean + modern)
  // ---------------------------------------------------------------------------
  static const Color _bg = Color(0xFFF7F8FA);
  static const Color _card = Colors.white;
  static const Color _border = Color(0xFFE6E8EE);
  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF4F46E5); // Indigo
  static const Color _danger = Color(0xFFDC2626);
  static const Color _success = Color(0xFF16A34A);

  final _repo = _QuestionRulesRepository();

  // ---------------------------------------------------------------------------
  // Form state
  // ---------------------------------------------------------------------------
  final _formKey = GlobalKey<FormState>();

  String? _setId;
  String _setTitle = '';

  String? _mainQuestionId;
  String? _triggerOptionId;

  bool _enableFollowUp = true;

  final _followUpQuestionCtrl = TextEditingController();
  String _followUpType = _QuestionType.labels.keys.first; // default
  bool _followUpRequired = false;

  final List<TextEditingController> _followUpOptionCtrls = [];

  bool _saving = false;

  // For table: optionally filter by "All / Selected set"
  bool get _hasSetSelected => (_setId ?? '').isNotEmpty;

  @override
  void initState() {
    super.initState();
    _ensureMinOptionRows();
  }

  @override
  void dispose() {
    _followUpQuestionCtrl.dispose();
    for (final c in _followUpOptionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _followUpNeedsOptions => _QuestionType.needsOptions(_followUpType);

  void _ensureMinOptionRows() {
    // For choice types, keep at least 2 visible rows for better UX
    if (_followUpOptionCtrls.isEmpty) {
      _followUpOptionCtrls.addAll([
        TextEditingController(text: 'Option 1'),
        TextEditingController(text: 'Option 2'),
      ]);
    }
  }

  void _resetForNewSet() {
    _mainQuestionId = null;
    _triggerOptionId = null;
    _enableFollowUp = true;
    _followUpQuestionCtrl.text = '';
    _followUpType = _QuestionType.labels.keys.first;
    _followUpRequired = false;

    for (final c in _followUpOptionCtrls) {
      c.dispose();
    }
    _followUpOptionCtrls.clear();
    _ensureMinOptionRows();
  }

  // ---------------------------------------------------------------------------
  // Save rule
  // ---------------------------------------------------------------------------
  Future<void> _createRule({
    required _QuestionDoc mainQ,
    required _OptionDoc triggerOpt,
  }) async {
    if (!_enableFollowUp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enable “Follow-up question” to create a rule.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.black87,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    // For choice follow-up types, validate options
    List<_NewOptionInput> followUpOptions = const [];
    if (_followUpNeedsOptions) {
      final labels = _followUpOptionCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      if (labels.length < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please add at least 1 option for the follow-up question.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: _danger,
          ),
        );
        return;
      }

      followUpOptions = [
        for (int i = 0; i < labels.length; i++)
          _NewOptionInput(
            label: labels[i],
            value: 'option_${i + 1}',
            requiresFreeText: false,
          ),
      ];
    }

    setState(() => _saving = true);
    try {
      await _repo.createConditionalQuestionWithOptions(
        questionSetId: _setId!,
        parentQuestionId: mainQ.id,
        triggerOptionId: triggerOpt.id,
        questionText: _followUpQuestionCtrl.text.trim(),
        questionType: _followUpType,
        isRequired: _followUpRequired,
        options: followUpOptions,
      );

      if (!mounted) return;

      // Reset only the follow-up inputs (keep selections)
      _followUpQuestionCtrl.text = '';
      _followUpRequired = false;

      for (final c in _followUpOptionCtrls) {
        c.dispose();
      }
      _followUpOptionCtrls.clear();
      _ensureMinOptionRows();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rule created successfully.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: _success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create rule: $e',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: _danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Delete rule (sub-question)
  // ---------------------------------------------------------------------------
  Future<void> _deleteRule(_QuestionDoc subQ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dctx) => AlertDialog(
        title: Text('Delete rule?', style: GoogleFonts.poppins()),
        content: Text(
          'This will delete the follow-up question and its options.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: _danger),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      await _repo.deleteQuestionWithOptions(subQ.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rule deleted.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.black87,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e', style: GoogleFonts.poppins()),
          backgroundColor: _danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isNarrow = w < 980;

    return DefaultTextStyle(
      style: GoogleFonts.poppins(color: _text),
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: _bg)),
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(
                          title: 'Question rules',
                          subtitle:
                              'Create follow-up questions that appear only when a guest selects a specific answer.',
                        ),
                        const SizedBox(height: 16),

                        // SET SELECTOR + BUILDER
                        _cardShell(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle(
                                  icon: Icons.tune_rounded,
                                  title: 'Rule builder',
                                  subtitle:
                                      'Pick a question set → pick a main question → pick an answer → add a follow-up question.',
                                ),
                                const SizedBox(height: 14),
                                _buildSetSelector(),
                                const SizedBox(height: 14),
                                if (!_hasSetSelected)
                                  _hintBanner(
                                    icon: Icons.info_outline_rounded,
                                    text:
                                        'Select a question set to load its questions and existing rules.',
                                  ),
                                if (_hasSetSelected) ...[
                                  const SizedBox(height: 10),
                                  _buildRuleBuilder(isNarrow: isNarrow),
                                ],
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // EXISTING RULES TABLE
                        _cardShell(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle(
                                  icon: Icons.rule_folder_rounded,
                                  title: 'Existing rules',
                                  subtitle:
                                      'Rules for the selected set are listed below. You can delete any rule.',
                                ),
                                const SizedBox(height: 14),
                                if (!_hasSetSelected)
                                  _emptyState(
                                    title: 'No set selected',
                                    body:
                                        'Choose a question set above to view its rules.',
                                  )
                                else
                                  _buildRulesTableOrCards(isNarrow: isNarrow),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_saving)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Widgets
  // ---------------------------------------------------------------------------

  Widget _buildSetSelector() {
    return StreamBuilder<List<_QuestionSetDoc>>(
      stream: _repo.streamQuestionSetsForCurrentUser(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _errorBanner('Failed to load question sets: ${snap.error}');
        }
        if (!snap.hasData) {
          return _smallLoader('Loading question sets…');
        }

        final sets = snap.data!;
        if (sets.isEmpty) {
          return _emptyState(
            title: 'No question sets yet',
            body:
                'Create a question set first, then come back to add question rules.',
          );
        }

        // ensure selected is valid
        if (_setId != null &&
            _setId!.isNotEmpty &&
            !sets.any((s) => s.id == _setId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _setId = null;
              _setTitle = '';
              _resetForNewSet();
            });
          });
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: _labeledField(
                label: 'Question set',
                helper: 'Rules are created inside a specific question set.',
                child: DropdownButtonFormField<String>(
                  value: _setId,
                  isExpanded: true,
                  decoration: _inputDecoration(),
                  items: [
                    for (final s in sets)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          s.title.isEmpty ? 'Untitled set' : s.title,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    final selected = sets.firstWhere((x) => x.id == v);

                    setState(() {
                      _setId = v;
                      _setTitle = selected.title.isEmpty
                          ? 'Untitled set'
                          : selected.title;
                      _resetForNewSet();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (_hasSetSelected)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: _success),
                    const SizedBox(width: 8),
                    Text(
                      _setTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _text,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRuleBuilder({required bool isNarrow}) {
    return StreamBuilder<List<_QuestionDoc>>(
      stream: _repo.streamQuestionsForSet(_setId!),
      builder: (context, qsnap) {
        if (qsnap.hasError) {
          return _errorBanner('Failed to load questions: ${qsnap.error}');
        }
        if (!qsnap.hasData) {
          return _smallLoader('Loading questions…');
        }

        final allQuestions = qsnap.data!;
        final baseQuestions =
            allQuestions.where((q) => q.parentQuestionId == null).toList();

        // ✅ Only allow main questions that should have selectable options
        final selectableMain = baseQuestions
            .where((q) => _QuestionType.needsOptions(q.questionType))
            .toList();

        _QuestionDoc? selectedMain;
        for (final q in selectableMain) {
          if (q.id == _mainQuestionId) {
            selectedMain = q;
            break;
          }
        }

        // If current selection disappeared, reset once (no flicker)
        if (_mainQuestionId != null && selectedMain == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _mainQuestionId = null;
              _triggerOptionId = null;
            });
          });
        }

        return Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _StepChip(step: '1', label: 'Pick question'),
                    _StepChip(step: '2', label: 'Pick answer'),
                    _StepChip(step: '3', label: 'Add follow-up'),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // MAIN QUESTION
              _labeledField(
                label: 'Main question',
                helper: 'Choose the question that controls the follow-up.',
                child: DropdownButtonFormField<String>(
                  value: _mainQuestionId,
                  isExpanded: true,
                  decoration: _inputDecoration(),
                  hint: Text(
                    'Select a main question',
                    style: GoogleFonts.poppins(fontSize: 13, color: _muted),
                  ),
                  items: [
                    for (final q in selectableMain)
                      DropdownMenuItem(
                        value: q.id,
                        child: Text(
                          q.questionText.isEmpty
                              ? '(Untitled question)'
                              : q.questionText,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _mainQuestionId = v;
                      _triggerOptionId = null;
                    });
                  },
                ),
              ),

              const SizedBox(height: 12),

              // If no selectable questions, show persistent message (NOT flickering)
              if (selectableMain.isEmpty)
                _hintBanner(
                  icon: Icons.warning_amber_rounded,
                  text:
                      'No multiple-choice / checkboxes / dropdown questions found in this set. Create one first (with options), then come back here.',
                  color: const Color(0xFFFFF7ED),
                  borderColor: const Color(0xFFFED7AA),
                  iconColor: const Color(0xFFEA580C),
                ),

              if (selectedMain != null) ...[
                // OPTIONS STREAM ONLY FOR SELECTED MAIN QUESTION
                StreamBuilder<List<_OptionDoc>>(
                  stream: _repo.streamOptionsForQuestion(selectedMain.id),
                  builder: (context, osnap) {
                    if (osnap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _errorBanner(
                            'Failed to load options: ${osnap.error}'),
                      );
                    }

                    if (!osnap.hasData) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _smallLoader('Loading options…'),
                      );
                    }

                    final options = osnap.data!;
                    _OptionDoc? selectedOpt;
                    for (final o in options) {
                      if (o.id == _triggerOptionId) {
                        selectedOpt = o;
                        break;
                      }
                    }

                    // reset invalid trigger selection if options changed
                    if (_triggerOptionId != null && selectedOpt == null) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!mounted) return;
                        setState(() => _triggerOptionId = null);
                      });
                    }

                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        _labeledField(
                          label: 'When guest selects',
                          helper:
                              'Pick the answer option that triggers the follow-up.',
                          child: DropdownButtonFormField<String>(
                            value: _triggerOptionId,
                            isExpanded: true,
                            decoration: _inputDecoration(),
                            hint: Text(
                              'Select an answer option',
                              style: GoogleFonts.poppins(
                                  fontSize: 13, color: _muted),
                            ),
                            items: [
                              for (final o in options)
                                DropdownMenuItem(
                                  value: o.id,
                                  child: Text(
                                    o.label.isEmpty
                                        ? '(Untitled option)'
                                        : o.label,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(fontSize: 14),
                                  ),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _triggerOptionId = v),
                          ),
                        ),

                        if (options.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _hintBanner(
                              icon: Icons.info_outline_rounded,
                              text:
                                  'This main question has no options yet. Add options in the Questions editor first.',
                            ),
                          ),

                        const SizedBox(height: 14),

                        // Follow-up toggle (now stable)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: _border),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.call_split_rounded,
                                  color: _primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Follow-up question for this answer',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Guests will see the follow-up only when they choose the selected answer.',
                                      style: GoogleFonts.poppins(
                                          fontSize: 12, color: _muted),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _enableFollowUp,
                                onChanged: (v) =>
                                    setState(() => _enableFollowUp = v),
                                activeColor: _primary,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Follow-up details card
                        Opacity(
                          opacity: _enableFollowUp ? 1 : 0.45,
                          child: IgnorePointer(
                            ignoring: !_enableFollowUp,
                            child: _followUpCard(isNarrow: isNarrow),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: (_saving ||
                                    !_enableFollowUp ||
                                    _triggerOptionId == null ||
                                    _triggerOptionId!.isEmpty)
                                ? null
                                : () => _createRule(
                                      mainQ: selectedMain!,
                                      triggerOpt: selectedOpt ??
                                          options.firstWhere(
                                              (o) => o.id == _triggerOptionId),
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.add_circle_outline_rounded,
                                size: 18),
                            label: Text(
                              'Create rule',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _mainQuestionDropdown(
      List<_QuestionWithOptions> selectableMainQuestions) {
    return _labeledField(
      label: 'Main question',
      helper: 'Choose the question that controls conditional behavior.',
      child: DropdownButtonFormField<String>(
        value: _mainQuestionId,
        isExpanded: true,
        decoration: _inputDecoration(),
        validator: (v) => (v == null || v.isEmpty) ? 'Select a question' : null,
        items: [
          for (final q in selectableMainQuestions)
            DropdownMenuItem(
              value: q.id,
              child: Text(
                q.question.questionText.isEmpty
                    ? '(Untitled question)'
                    : q.question.questionText,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
        ],
        onChanged: (v) {
          setState(() {
            _mainQuestionId = v;
            _triggerOptionId = null;
          });
        },
      ),
    );
  }

  Widget _triggerOptionDropdown(_QuestionWithOptions? mainQ) {
    final options = mainQ?.options ?? const <_OptionDoc>[];

    return _labeledField(
      label: 'When guest selects',
      helper: 'Pick the answer option that triggers the follow-up.',
      child: DropdownButtonFormField<String>(
        value: _triggerOptionId,
        isExpanded: true,
        decoration: _inputDecoration(),
        validator: (v) => (v == null || v.isEmpty) ? 'Select an answer' : null,
        items: [
          for (final o in options)
            DropdownMenuItem(
              value: o.id,
              child: Text(
                o.label.isEmpty ? '(Untitled option)' : o.label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
        ],
        onChanged: (v) => setState(() => _triggerOptionId = v),
      ),
    );
  }

  Widget _followUpCard({required bool isNarrow}) {
    if (_followUpOptionCtrls.isEmpty) _ensureMinOptionRows();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Follow-up question',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const SizedBox(height: 10),

          // Text + Type row
          isNarrow
              ? Column(
                  children: [
                    _labeledField(
                      label: 'Question text',
                      helper: 'What should the guest be asked next?',
                      child: TextFormField(
                        controller: _followUpQuestionCtrl,
                        decoration: _inputDecoration(
                          hint: 'e.g. Which veg starters do you prefer?',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter the follow-up question text'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _labeledField(
                      label: 'Answer type',
                      helper: 'How should the guest respond?',
                      child: DropdownButtonFormField<String>(
                        value: _followUpType,
                        decoration: _inputDecoration(),
                        items: [
                          for (final e in _QuestionType.labels.entries)
                            DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value,
                                  style: GoogleFonts.poppins(fontSize: 14)),
                            ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            _followUpType = v;
                            if (_QuestionType.needsOptions(_followUpType)) {
                              _ensureMinOptionRows();
                            }
                          });
                        },
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _labeledField(
                        label: 'Question text',
                        helper: 'What should the guest be asked next?',
                        child: TextFormField(
                          controller: _followUpQuestionCtrl,
                          decoration: _inputDecoration(
                            hint: 'e.g. Which veg starters do you prefer?',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter the follow-up question text'
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _labeledField(
                        label: 'Answer type',
                        helper: 'How should the guest respond?',
                        child: DropdownButtonFormField<String>(
                          value: _followUpType,
                          decoration: _inputDecoration(),
                          items: [
                            for (final e in _QuestionType.labels.entries)
                              DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value,
                                    style: GoogleFonts.poppins(fontSize: 14)),
                              ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setState(() {
                              _followUpType = v;
                              if (_QuestionType.needsOptions(_followUpType)) {
                                _ensureMinOptionRows();
                              }
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),

          const SizedBox(height: 10),

          // Required toggle
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, size: 18, color: _muted),
                    const SizedBox(width: 8),
                    Text(
                      'Required',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _text,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Switch(
                      value: _followUpRequired,
                      onChanged: (v) => setState(() => _followUpRequired = v),
                      activeColor: _primary,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _typePill(_followUpType),
            ],
          ),

          if (_followUpNeedsOptions) ...[
            const SizedBox(height: 10),
            Divider(color: _border, height: 1),
            const SizedBox(height: 12),
            Text(
              'Options',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add the available choices for the follow-up question.',
              style: GoogleFonts.poppins(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < _followUpOptionCtrls.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _followUpOptionCtrls[i],
                        decoration: _inputDecoration(hint: 'Option ${i + 1}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      tooltip: 'Remove option',
                      onPressed: _followUpOptionCtrls.length <= 1
                          ? null
                          : () {
                              setState(() {
                                final c = _followUpOptionCtrls.removeAt(i);
                                c.dispose();
                              });
                            },
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _followUpOptionCtrls.add(
                      TextEditingController(
                        text: 'Option ${_followUpOptionCtrls.length + 1}',
                      ),
                    );
                  });
                },
                icon: const Icon(Icons.add_rounded, color: _primary),
                label: Text(
                  'Add option',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: _primary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRulesTableOrCards({required bool isNarrow}) {
    return StreamBuilder<List<_QuestionWithOptions>>(
      stream: _repo.streamQuestionsWithOptionsForSet(_setId!),
      builder: (context, snap) {
        if (snap.hasError) {
          return _errorBanner('Failed to load rules: ${snap.error}');
        }
        if (!snap.hasData) {
          return _smallLoader('Loading rules…');
        }

        final all = snap.data!;
        final questions = {for (final q in all) q.id: q.question};

        // Map options by id (for trigger option label)
        final optionLabelById = <String, String>{};
        for (final q in all) {
          for (final o in q.options) {
            optionLabelById[o.id] = o.label;
          }
        }

        // Rules are sub-questions (parentQuestionId != null)
        final rules = all
            .map((q) => q.question)
            .where(
                (q) => q.parentQuestionId != null && q.triggerOptionId != null)
            .toList();

        if (rules.isEmpty) {
          return _emptyState(
            title: 'No rules yet',
            body: 'Create your first rule using the Rule builder above.',
          );
        }

        // Sort (stable)
        rules.sort((a, b) {
          final ap =
              (a.parentQuestionId ?? '').compareTo(b.parentQuestionId ?? '');
          if (ap != 0) return ap;
          return (a.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                  b.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0));
        });

        if (isNarrow) {
          // Card list on narrow screens
          return Column(
            children: [
              for (final r in rules)
                _ruleCard(
                  rule: r,
                  parent: questions[r.parentQuestionId],
                  triggerLabel: optionLabelById[r.triggerOptionId!] ?? '—',
                ),
            ],
          );
        }

        // DataTable on wide screens
        return _rulesTable(
          rules: rules,
          questionsById: questions,
          optionLabelById: optionLabelById,
        );
      },
    );
  }

  Widget _rulesTable({
    required List<_QuestionDoc> rules,
    required Map<String, _QuestionDoc> questionsById,
    required Map<String, String> optionLabelById,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Scrollbar(
          thumbVisibility: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 980),
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor:
                      WidgetStatePropertyAll(const Color(0xFFF3F4F6)),
                  headingTextStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: _text,
                  ),
                  dataTextStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: _text,
                  ),
                  columns: const [
                    DataColumn(label: Text('Main question')),
                    DataColumn(label: Text('When answer is')),
                    DataColumn(label: Text('Follow-up question')),
                    DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Required')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (final r in rules)
                      DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: 260,
                              child: Text(
                                (questionsById[r.parentQuestionId]
                                                ?.questionText)
                                            ?.trim()
                                            .isNotEmpty ==
                                        true
                                    ? questionsById[r.parentQuestionId]!
                                        .questionText
                                    : '—',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 190,
                              child: Text(
                                optionLabelById[r.triggerOptionId!] ?? '—',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 300,
                              child: Text(
                                r.questionText.isEmpty ? '—' : r.questionText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(_typePill(r.questionType)),
                          DataCell(
                            _boolPill(r.isRequired),
                          ),
                          DataCell(
                            IconButton(
                              tooltip: 'Delete rule',
                              onPressed: _saving ? null : () => _deleteRule(r),
                              icon: const Icon(Icons.delete_outline_rounded),
                              color: _danger,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _ruleCard({
    required _QuestionDoc rule,
    required _QuestionDoc? parent,
    required String triggerLabel,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            parent?.questionText.isNotEmpty == true
                ? parent!.questionText
                : '—',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _miniTag('When', Icons.subdirectory_arrow_right_rounded),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  triggerLabel,
                  style: GoogleFonts.poppins(fontSize: 12.5, color: _muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            rule.questionText.isEmpty ? '—' : rule.questionText,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _text,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _typePill(rule.questionType),
              const SizedBox(width: 8),
              _boolPill(rule.isRequired),
              const Spacer(),
              IconButton(
                tooltip: 'Delete rule',
                onPressed: _saving ? null : () => _deleteRule(rule),
                icon: const Icon(Icons.delete_outline_rounded),
                color: _danger,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  Widget _cardShell({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDE1FF)),
          ),
          child: const Icon(Icons.rule_rounded, color: _primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: _muted,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _labeledField({
    required String label,
    required String helper,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: _text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            color: _muted,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(fontSize: 13, color: _muted),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
    );
  }

  Widget _typePill(String type) {
    final label = _QuestionType.labelFor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDDE1FF)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: _primary,
        ),
      ),
    );
  }

  Widget _boolPill(bool value) {
    final text = value ? 'Yes' : 'No';
    final bg = value ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB);
    final br = value ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A);
    final fg = value ? const Color(0xFF16A34A) : const Color(0xFFB45309);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: br),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _miniTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallLoader(String text) {
    return Row(
      children: [
        const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2.6),
        ),
        const SizedBox(width: 10),
        Text(text, style: GoogleFonts.poppins(color: _muted)),
      ],
    );
  }

  Widget _errorBanner(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: _danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hintBanner({
    required IconData icon,
    required String text,
    Color color = const Color(0xFFEFF6FF),
    Color borderColor = const Color(0xFFBFDBFE),
    Color iconColor = const Color(0xFF2563EB),
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: _text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState({required String title, required String body}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.inbox_rounded, color: _muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    color: _muted,
                    fontSize: 12.5,
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
// Header
// -----------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final String title;
  final String subtitle;

  const _Header({
    required this.title,
    required this.subtitle,
  });

  static const Color _text = Color(0xFF111827);
  static const Color _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.rule_rounded, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Step chip
// -----------------------------------------------------------------------------
class _StepChip extends StatelessWidget {
  final String step;
  final String label;

  const _StepChip({required this.step, required this.label});

  static const Color _border = Color(0xFFE6E8EE);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _text = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _border),
            ),
            child: Text(
              step,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _muted,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _text,
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Question Type helper
// -----------------------------------------------------------------------------
class _QuestionType {
  static const labels = <String, String>{
    'short_answer': 'Short answer',
    'paragraph': 'Paragraph',
    'multiple_choice': 'Multiple choice',
    'checkboxes': 'Checkboxes',
    'dropdown': 'Dropdown',
  };

  static String labelFor(String type) => labels[type] ?? 'Multiple choice';

  static bool needsOptions(String type) =>
      type == 'multiple_choice' || type == 'checkboxes' || type == 'dropdown';
}

// -----------------------------------------------------------------------------
// Firestore repository (self-contained)
// -----------------------------------------------------------------------------
class _QuestionRulesRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // You already store sets in 'demographicQuestionSets'
  Stream<List<_QuestionSetDoc>> streamQuestionSetsForCurrentUser() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('demographicQuestionSets')
        .where('isDisabled', isEqualTo: false)
        .where('userId', isEqualTo: uid)
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs.map((d) => _QuestionSetDoc.fromDoc(d)).toList();
    });
  }

  Stream<List<_QuestionDoc>> streamQuestionsForSet(String setId) {
    return _db
        .collection('demographicQuestions')
        .where('isDisabled', isEqualTo: false)
        .where('questionSetId', isEqualTo: setId)
        .orderBy('displayOrder')
        .snapshots()
        .map((snap) => snap.docs.map((d) => _QuestionDoc.fromDoc(d)).toList());
  }

  Stream<List<_OptionDoc>> streamOptionsForQuestion(String questionId) {
    return _db
        .collection('demographicQuestionOptions')
        .where('isDisabled', isEqualTo: false)
        .where('questionId', isEqualTo: questionId)
        .orderBy('displayOrder')
        .snapshots()
        .map((snap) => snap.docs.map((d) => _OptionDoc.fromDoc(d)).toList());
  }

  /// Stream ALL questions for a set (base + conditional) + their options.
  /// This lets the rules table show parent + trigger option labels.
  Stream<List<_QuestionWithOptions>> streamQuestionsWithOptionsForSet(
      String setId) {
    final controller = StreamController<List<_QuestionWithOptions>>();

    StreamSubscription? qSub;
    final optSubs = <StreamSubscription>[];

    QuerySnapshot<Map<String, dynamic>>? latestQuestionsSnap;
    final Map<String, _OptionDoc> optionById = {};

    void emit() {
      if (latestQuestionsSnap == null) return;

      final questions = latestQuestionsSnap!.docs
          .map((d) => _QuestionDoc.fromDoc(d))
          .toList();

      if (questions.isEmpty) {
        controller.add(const []);
        return;
      }

      // group options by questionId
      final Map<String, List<_OptionDoc>> byQuestionId = {};
      for (final opt in optionById.values) {
        byQuestionId.putIfAbsent(opt.questionId, () => []).add(opt);
      }

      final combined = <_QuestionWithOptions>[];
      for (final q in questions) {
        final opts = List<_OptionDoc>.from(byQuestionId[q.id] ?? const [])
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
        combined.add(_QuestionWithOptions(question: q, options: opts));
      }

      controller.add(combined);
    }

    void resetOptionStreams(List<String> questionIds) {
      for (final s in optSubs) {
        s.cancel();
      }
      optSubs.clear();
      optionById.clear();

      if (questionIds.isEmpty) {
        emit();
        return;
      }

      // Firestore whereIn max 30 => chunk
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
            final opt = _OptionDoc.fromDoc(d);
            optionById[opt.id] = opt;
          }
          emit();
        });

        optSubs.add(sub);
      }
    }

    qSub = _db
        .collection('demographicQuestions')
        .where('isDisabled', isEqualTo: false)
        .where('questionSetId', isEqualTo: setId)
        .orderBy('displayOrder')
        .snapshots()
        .listen((qsnap) {
      latestQuestionsSnap = qsnap;
      final ids = qsnap.docs.map((d) => d.id).toList();
      resetOptionStreams(ids);
      emit();
    });

    controller.onCancel = () async {
      await qSub?.cancel();
      for (final s in optSubs) {
        await s.cancel();
      }
      await controller.close();
    };

    return controller.stream;
  }

  Future<void> createConditionalQuestionWithOptions({
    required String questionSetId,
    required String parentQuestionId,
    required String triggerOptionId,
    required String questionText,
    required String questionType,
    required bool isRequired,
    required List<_NewOptionInput> options,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');

    final batch = _db.batch();
    final questionsCol = _db.collection('demographicQuestions');
    final optionsCol = _db.collection('demographicQuestionOptions');

    final questionDoc = questionsCol.doc();
    final questionId = questionDoc.id;

    final now = FieldValue.serverTimestamp();

    // sub-question doc
    batch.set(questionDoc, {
      'questionId': questionId,
      'questionSetId': questionSetId,
      'questionText': questionText,
      'questionType': questionType,
      'userId': uid,
      'displayOrder':
          9999, // not shown in base editor (filter parentQuestionId == null)
      'isRequired': isRequired,
      'isDisabled': false,
      'createdDate': now,
      'modifiedDate': now,

      // ✅ RULE FIELDS
      'parentQuestionId': parentQuestionId,
      'triggerOptionId': triggerOptionId,
    });

    // options for follow-up (only for choice types)
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

  Future<void> deleteQuestionWithOptions(String questionId) async {
    final uid = _uid;
    if (uid == null) throw Exception('User not authenticated');

    final batch = _db.batch();

    // delete question
    final qRef = _db.collection('demographicQuestions').doc(questionId);
    batch.delete(qRef);

    // delete its options
    final optsSnap = await _db
        .collection('demographicQuestionOptions')
        .where('questionId', isEqualTo: questionId)
        .get();

    for (final d in optsSnap.docs) {
      batch.delete(d.reference);
    }

    await batch.commit();
  }
}

// -----------------------------------------------------------------------------
// Minimal models (self-contained)
// -----------------------------------------------------------------------------
class _QuestionSetDoc {
  final String id;
  final String title;
  final String description;
  final String celebrationType;

  _QuestionSetDoc({
    required this.id,
    required this.title,
    required this.description,
    required this.celebrationType,
  });

  factory _QuestionSetDoc.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return _QuestionSetDoc(
      id: doc.id,
      title: (data['title'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      celebrationType: (data['celebrationType'] ?? '').toString(),
    );
  }
}

class _QuestionWithOptions {
  final _QuestionDoc question;
  final List<_OptionDoc> options;

  _QuestionWithOptions({required this.question, required this.options});

  String get id => question.id;
}

class _QuestionDoc {
  final String id;
  final String questionSetId;
  final String questionText;
  final String questionType;
  final bool isRequired;
  final int displayOrder;

  // ✅ rule fields (nullable)
  final String? parentQuestionId;
  final String? triggerOptionId;

  // Optional, for sorting/display
  final DateTime? createdDate;

  _QuestionDoc({
    required this.id,
    required this.questionSetId,
    required this.questionText,
    required this.questionType,
    required this.isRequired,
    required this.displayOrder,
    required this.parentQuestionId,
    required this.triggerOptionId,
    required this.createdDate,
  });

  factory _QuestionDoc.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final created = data['createdDate'];
    DateTime? createdDate;
    if (created is Timestamp) createdDate = created.toDate();

    return _QuestionDoc(
      id: doc.id,
      questionSetId: (data['questionSetId'] ?? '').toString(),
      questionText: (data['questionText'] ?? '').toString(),
      questionType: (data['questionType'] ?? 'multiple_choice').toString(),
      isRequired: (data['isRequired'] ?? false) == true,
      displayOrder: (data['displayOrder'] is num)
          ? (data['displayOrder'] as num).toInt()
          : int.tryParse('${data['displayOrder']}') ?? 0,
      parentQuestionId: data['parentQuestionId']?.toString(),
      triggerOptionId: data['triggerOptionId']?.toString(),
      createdDate: createdDate,
    );
  }
}

class _OptionDoc {
  final String id;
  final String questionId;
  final String label;
  final int displayOrder;

  _OptionDoc({
    required this.id,
    required this.questionId,
    required this.label,
    required this.displayOrder,
  });

  factory _OptionDoc.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return _OptionDoc(
      id: doc.id,
      questionId: (data['questionId'] ?? '').toString(),
      label: (data['label'] ?? '').toString(),
      displayOrder: (data['displayOrder'] is num)
          ? (data['displayOrder'] as num).toInt()
          : int.tryParse('${data['displayOrder']}') ?? 0,
    );
  }
}

class _NewOptionInput {
  final String label;
  final String value;
  final bool requiresFreeText;

  _NewOptionInput({
    required this.label,
    required this.value,
    required this.requiresFreeText,
  });
}
