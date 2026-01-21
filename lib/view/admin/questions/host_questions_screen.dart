// lib/views/host_questions_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/controller/admin_controllers/host_questions_controller.dart';
import 'package:traxx_wepapp/layout/headers/widgets/add_question_dialog.dart';
import 'package:traxx_wepapp/models/host_questions_option.dart';
import 'package:google_fonts/google_fonts.dart';

// 🔹 New bright palette
const Color kAccent = Color(0xFF6C4BFF);
const Color kAccentLight = Color(0xFFA18CFF);
const Color kPanelBg = Color(0xFFF4E9FF); // vertical purple-ish area
const Color kBorder = Color(0xFFE5E5E5);
const Color kTextDark = Color(0xFF1A1A1A);
const Color kTextBody = Color(0xFF333333);
const Color kGfPurple = Color(0xFF673AB7); // header stripe + button
const Color kGfBackground = Color(0xFFF1EBFF); // page background (lavender)
const Color _gfBackground = Color(0xFFF4F0FB);
const Color _gfPurple = Color(0xFF673AB7);
const Color _gfTextColor = Color(0xFF202124);

class HostQuestionsScreen extends StatefulWidget {
  final String questionSetId;

  const HostQuestionsScreen({
    super.key,
    required this.questionSetId,
  });

  @override
  State<HostQuestionsScreen> createState() => _HostQuestionsScreenState();
}

class _HostQuestionsScreenState extends State<HostQuestionsScreen>
    with SingleTickerProviderStateMixin {
  late final HostQuestionsController _controller;

  String? _activeQuestionId;
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, Timer> _optionDebounceTimers = {};
  bool _pendingFocusNew = false;
  bool _isProcessing = false;
  final ScrollController _listScrollCtrl = ScrollController();

  String _setTitle = '';
  String _setDescription = '';
  bool _metaLoading = true;

  void _setProcessing(bool value) {
    if (!mounted) return;
    setState(() => _isProcessing = value);
  }

  @override
  void initState() {
    super.initState();
    _controller =
        HostQuestionsController(firestore: FirebaseFirestore.instance);
    _loadSetMeta();
  }

  @override
  void dispose() {
    _listScrollCtrl.dispose();
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    for (final t in _optionDebounceTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _setActiveQuestion(String id) {
    if (_activeQuestionId == id) return;
    setState(() => _activeQuestionId = id);
  }

  Future<void> _loadSetMeta() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('demographicQuestionSets')
          .doc(widget.questionSetId)
          .get();

      final data = doc.data() ?? {};
      if (!mounted) return;

      setState(() {
        _setTitle = (data['title'] ?? '').toString();
        _setDescription = (data['description'] ?? '').toString();
        _metaLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _metaLoading = false);
    }
  }

  void _debouncedUpdateQuestion(
      String questionDocId, Map<String, dynamic> data) {
    final key = questionDocId;
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(const Duration(milliseconds: 400), () {
      _controller.updateQuestion(questionDocId: questionDocId, data: data);
    });
  }

  void _debouncedUpdateOption(String optionDocId, Map<String, dynamic> data) {
    final key = 'opt_$optionDocId';
    _optionDebounceTimers[key]?.cancel();
    _optionDebounceTimers[key] = Timer(const Duration(milliseconds: 400), () {
      _controller.updateOption(optionDocId: optionDocId, data: data);
    });
  }

  Future<void> _addOption(DemographicQuestionWithOptions item) async {
    _setProcessing(true);
    try {
      final nextOrder =
          item.options.isNotEmpty ? (item.options.last.displayOrder + 1) : 1;

      final newOpt = await _controller.createOption(
        questionId: item.question.questionId,
        displayOrder: nextOrder,
      );

      if (!mounted) return;
      setState(() => item.options.add(newOpt));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to add option: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> _removeOption(
    DemographicQuestionWithOptions item,
    DemographicQuestionOption opt,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete option?', style: GoogleFonts.poppins()),
        content: Text('Do you want to delete "${opt.label}"?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _setProcessing(true);
    try {
      await _controller.deleteOption(opt.id);

      if (!mounted) return;
      setState(() => item.options.removeWhere((o) => o.id == opt.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to delete option: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> _updateQuestionType(String questionId, String type) async {
    _setProcessing(true);
    try {
      await _controller.updateQuestion(
        questionDocId: questionId,
        data: {'questionType': type},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to update type: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> _updateRequired(String questionId, bool value) async {
    _setProcessing(true);
    try {
      await _controller.updateQuestion(
        questionDocId: questionId,
        data: {'isRequired': value},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update required: $e',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> _confirmDeleteQuestion(
      DemographicQuestionWithOptions item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete question?', style: GoogleFonts.poppins()),
        content: Text(
          'This will permanently delete the question and its options.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _setProcessing(true);
    try {
      await _controller.deleteQuestionWithOptions(item.question.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete question: $e',
              style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _setProcessing(false);
    }
  }

  // ✅ REMOVE RULE (make follow-up a normal base question again)
  Future<void> _confirmRemoveRule(
    DemographicQuestionWithOptions item,
    List<DemographicQuestionWithOptions> allItems,
  ) async {
    final bool isFollowUp =
        (item.question.parentQuestionId?.trim().isNotEmpty ?? false);

    if (!isFollowUp) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remove rule?', style: GoogleFonts.poppins()),
        content: Text(
          'This will unlink the follow-up and make it a normal question again.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Remove', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _setProcessing(true);
    try {
      // place as last base question
      final base = allItems.where((x) {
        final p = x.question.parentQuestionId?.trim() ?? '';
        return p.isEmpty;
      }).toList();

      int maxBaseOrder = 0;
      for (final b in base) {
        if (b.question.displayOrder > maxBaseOrder) {
          maxBaseOrder = b.question.displayOrder;
        }
      }

      await _controller.updateQuestion(
        questionDocId: item.question.id,
        data: {
          'parentQuestionId': FieldValue.delete(),
          'triggerOptionId': FieldValue.delete(),
          'displayOrder': maxBaseOrder + 1,
          'modifiedDate': FieldValue.serverTimestamp(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rule removed.', style: GoogleFonts.poppins()),
          backgroundColor: Colors.black87,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to remove rule: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> _handleAddQuestion() async {
    _pendingFocusNew = true;

    final bool? created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddQuestionDialog(questionSetId: widget.questionSetId),
    );

    if (created == true) {
      _setProcessing(true);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _setProcessing(false);
      });
    } else {
      _pendingFocusNew = false;
    }
  }

  Future<void> _openAddRulesDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddRulesDialog(
        questionSetId: widget.questionSetId,
        controller: _controller,
      ),
    );
  }

  Future<void> _openShowRulesDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ShowRulesDialog(
        questionSetId: widget.questionSetId,
        controller: _controller,
      ),
    );
  }

  Widget _buildAddQuestionBtn({bool fullWidth = false}) => SizedBox(
        height: 44,
        width: fullWidth ? double.infinity : null,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _handleAddQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: kGfPurple,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          child: const Text('Add Question'),
        ),
      );

  Widget _buildAddRuleBtn({bool fullWidth = false}) => SizedBox(
        height: 44,
        width: fullWidth ? double.infinity : null,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _openAddRulesDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: kGfPurple,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          child: const Text('Add Rule'),
        ),
      );

  Widget _buildShowRulesBtn({bool fullWidth = false}) => SizedBox(
        height: 44,
        width: fullWidth ? double.infinity : null,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _openShowRulesDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: kGfPurple,
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          child: const Text('Show Rules'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);

        final double boundedH = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : media.size.height;

        final double screenW = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : media.size.width;

        final isPhone = screenW < 600;
        final isNarrow = screenW < 900;

        // ✅ better width rules per device
        final maxBodyWidth = isPhone
            ? screenW // full width on phone
            : math.min(screenW * 0.86, 1180.0);

        final horizontalPad = isPhone ? 14.0 : 40.0;
        final topPad = isPhone ? 14.0 : 24.0;
        final bottomPad = isPhone ? 16.0 : 24.0;

        return SizedBox(
          height: boundedH,
          width: double.infinity,
          child: DefaultTextStyle(
            style: GoogleFonts.poppins(),
            child: Stack(
              children: [
                const Positioned.fill(child: ColoredBox(color: _gfBackground)),
                Column(
                  children: [
                    // ✅ header area
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          horizontalPad, topPad, horizontalPad, 10),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxBodyWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFormHeaderCard(isPhone: isPhone),
                              const SizedBox(height: 12),

                              // ✅ buttons: stack on phone, wrap on tablet, row on desktop
                              if (isPhone) ...[
                                SizedBox(
                                    width: double.infinity,
                                    child:
                                        _buildAddQuestionBtn(fullWidth: true)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                        child:
                                            _buildAddRuleBtn(fullWidth: true)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: _buildShowRulesBtn(
                                            fullWidth: true)),
                                  ],
                                ),
                              ] else ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: [
                                      _buildAddQuestionBtn(),
                                      _buildAddRuleBtn(),
                                      _buildShowRulesBtn(),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 10),
                              Center(
                                child: Text(
                                  'Click on a question to edit',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ✅ list scrolls
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            horizontalPad, 0, horizontalPad, bottomPad),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxBodyWidth),
                            child: _buildQuestionsStream(
                                isPhone: isPhone, isNarrow: isNarrow),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isProcessing)
                  Positioned.fill(
                    child: Container(
                      color: _gfBackground.withOpacity(0.35),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: _gfPurple,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormHeaderCard({required bool isPhone}) {
    final title = _setTitle.isEmpty ? 'Untitled form' : _setTitle;
    final description =
        _setDescription.isEmpty ? 'Form description' : _setDescription;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: const BoxDecoration(
              color: kGfPurple,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              isPhone ? 16 : 24,
              isPhone ? 14 : 18,
              isPhone ? 16 : 24,
              isPhone ? 16 : 22,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: isPhone ? 18 : 28,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: isPhone ? 13 : 14,
                    fontWeight: FontWeight.w600,
                    color: kTextDark.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsStream(
      {required bool isPhone, required bool isNarrow}) {
    return StreamBuilder<List<DemographicQuestionWithOptions>>(
      stream: _controller.streamQuestions(
        questionSetId: widget.questionSetId,
        includeConditional: true,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final err = snapshot.error;
          if (kDebugMode) debugPrint('🔥 HostQuestionsScreen error: $err');
          return _buildErrorState(err.toString());
        }

        if (!snapshot.hasData) {
          return _buildLoadingSkeleton();
        }

        final items = snapshot.data!;
        if (items.isEmpty) return _buildEmptyState();

        final all = List<DemographicQuestionWithOptions>.from(items);

        // Build option label map (needed to display trigger label for follow-ups)
        final optionLabelById = <String, String>{};
        for (final it in all) {
          for (final opt in it.options) {
            optionLabelById[opt.id] = opt.label;
          }
        }

        // split base/sub
        final base = all.where((x) {
          final p = x.question.parentQuestionId?.trim() ?? '';
          return p.isEmpty;
        }).toList()
          ..sort((a, b) =>
              a.question.displayOrder.compareTo(b.question.displayOrder));

        final subs = all.where((x) {
          final p = x.question.parentQuestionId?.trim() ?? '';
          return p.isNotEmpty;
        }).toList();

        // group subs by parent doc-id
        final Map<String, List<DemographicQuestionWithOptions>> subsByParent =
            {};
        for (final s in subs) {
          final parentId = s.question.parentQuestionId!.trim();
          subsByParent.putIfAbsent(parentId, () => []).add(s);
        }

        // sort subs
        for (final entry in subsByParent.entries) {
          entry.value.sort((a, b) =>
              a.question.displayOrder.compareTo(b.question.displayOrder));
        }

        // render: base + its subs
        final renderList = <_HostRenderRow>[];
        final usedSubIds = <String>{};

        for (final b in base) {
          renderList.add(_HostRenderRow(item: b, isSub: false));
          final children = subsByParent[b.question.id] ?? const [];
          for (final c in children) {
            renderList.add(_HostRenderRow(item: c, isSub: true));
            usedSubIds.add(c.question.id);
          }
        }

        // orphan subs (if parent missing) -> append at end
        final orphanSubs =
            subs.where((s) => !usedSubIds.contains(s.question.id)).toList();
        if (orphanSubs.isNotEmpty) {
          orphanSubs.sort((a, b) =>
              a.question.displayOrder.compareTo(b.question.displayOrder));
          for (final o in orphanSubs) {
            renderList.add(_HostRenderRow(item: o, isSub: true));
          }
        }

        if (_pendingFocusNew && all.isNotEmpty) {
          _pendingFocusNew = false;
          final newId = all.last.question.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _setActiveQuestion(newId);
          });
        }

        return Scrollbar(
          controller: _listScrollCtrl,
          thumbVisibility: !isPhone,
          child: ListView.builder(
            controller: _listScrollCtrl,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: renderList.length,
            itemBuilder: (context, index) {
              final row = renderList[index];
              final item = row.item;

              final isFollowUp = row.isSub;
              final triggerLabel = isFollowUp
                  ? (optionLabelById[item.question.triggerOptionId ?? ''] ?? '')
                  : null;

              return Padding(
                key: ValueKey(item.question.id),
                padding: const EdgeInsets.only(bottom: 12),
                child: _GoogleFormsQuestionCard(
                  compact: isPhone || isNarrow,
                  index: index,
                  item: item,
                  isActive: item.question.id == _activeQuestionId,
                  isFollowUp: isFollowUp,
                  followUpTriggerLabel: triggerLabel,
                  onTap: () => _setActiveQuestion(item.question.id),
                  onQuestionTextChanged: (text) => _debouncedUpdateQuestion(
                    item.question.id,
                    {'questionText': text},
                  ),
                  onQuestionTypeChanged: (type) =>
                      _updateQuestionType(item.question.id, type),
                  onRequiredChanged: (required) =>
                      _updateRequired(item.question.id, required),
                  onDelete: () => _confirmDeleteQuestion(item),
                  onRemoveRule:
                      isFollowUp ? () => _confirmRemoveRule(item, all) : null,
                  onRemoveOption: (opt) => _removeOption(item, opt),
                  onAddOption: () => _addOption(item),
                  onOptionLabelChanged: (opt, newLabel) {
                    if (opt.id.isEmpty) return;
                    _debouncedUpdateOption(opt.id, {'label': newLabel});
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ---------------- STATES ----------------

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Row(
            children: [
              const SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(strokeWidth: 3, color: kGfPurple),
              ),
              const SizedBox(width: 14),
              Text(
                'Loading questions…',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kTextDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Card(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              Icon(Icons.help_outline_rounded, size: 48, color: kGfPurple),
              const SizedBox(height: 16),
              Text(
                'No questions yet',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Start by adding your first question using the "Add Question" button.',
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
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Failed to load questions: $error',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShowRulesDialog extends StatefulWidget {
  final String questionSetId;
  final HostQuestionsController controller;

  const ShowRulesDialog({
    super.key,
    required this.questionSetId,
    required this.controller,
  });

  @override
  State<ShowRulesDialog> createState() => _ShowRulesDialogState();
}

class _ShowRulesDialogState extends State<ShowRulesDialog> {
  bool _saving = false;

  Future<void> _removeRule({
    required String followUpDocId,
    required List<DemographicQuestionWithOptions> allItems,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Remove rule?', style: GoogleFonts.poppins()),
        content: Text(
          'This will unlink the follow-up and make it a normal question again.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text('Remove', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _saving = true);
    try {
      final base = allItems.where((x) {
        final p = x.question.parentQuestionId?.trim() ?? '';
        return p.isEmpty;
      }).toList();

      int maxBaseOrder = 0;
      for (final b in base) {
        if (b.question.displayOrder > maxBaseOrder)
          maxBaseOrder = b.question.displayOrder;
      }

      await widget.controller.updateQuestion(
        questionDocId: followUpDocId,
        data: {
          'parentQuestionId': FieldValue.delete(),
          'triggerOptionId': FieldValue.delete(),
          'displayOrder': maxBaseOrder + 1,
          'modifiedDate': FieldValue.serverTimestamp(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rule removed.', style: GoogleFonts.poppins())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to remove rule: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editRule({
    required List<DemographicQuestionWithOptions> all,
    required DemographicQuestionWithOptions followUp,
  }) async {
    final res = await showDialog<_RuleEditResult?>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditRuleDialog(
        questionSetId: widget.questionSetId,
        controller: widget.controller,
        allItems: all,
        followUp: followUp,
      ),
    );

    if (res == null) return;

    setState(() => _saving = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('demographicQuestions')
          .where('isDisabled', isEqualTo: false)
          .where('questionSetId', isEqualTo: widget.questionSetId)
          .where('parentQuestionId', isEqualTo: res.parentQuestionId)
          .get();

      int maxOrder = 0;
      for (final d in snap.docs) {
        final v = d.data()['displayOrder'];
        final n = (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
        if (n > maxOrder) maxOrder = n;
      }

      await widget.controller.updateQuestion(
        questionDocId: followUp.question.id,
        data: {
          'parentQuestionId': res.parentQuestionId,
          'triggerOptionId': res.triggerOptionId,
          'displayOrder': maxOrder + 1,
          'modifiedDate': FieldValue.serverTimestamp(),
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rule updated.', style: GoogleFonts.poppins())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to update rule: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final listH = math.min(h * 0.62, 520.0);

    return _GfDialogFrame(
      title: 'Rules',
      icon: Icons.rule_folder_rounded,
      disableClose: _saving,
      onClose: () => Navigator.pop(context),
      body: SizedBox(
        height: listH,
        child: StreamBuilder<List<DemographicQuestionWithOptions>>(
          stream: widget.controller.streamQuestions(
            questionSetId: widget.questionSetId,
            includeConditional: true,
          ),
          builder: (context, snap) {
            if (snap.hasError) {
              return Text('Failed to load rules: ${snap.error}',
                  style: GoogleFonts.poppins());
            }
            if (!snap.hasData) {
              return Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: 12),
                  Text('Loading…', style: GoogleFonts.poppins()),
                ],
              );
            }

            final all = snap.data!;

            final questionTextById = <String, String>{};
            final optionLabelById = <String, String>{};
            for (final it in all) {
              questionTextById[it.question.id] = it.question.questionText;
              for (final opt in it.options) {
                optionLabelById[opt.id] = opt.label;
              }
            }

            final rules = all.where((x) {
              final p = x.question.parentQuestionId?.trim() ?? '';
              return p.isNotEmpty;
            }).toList();

            if (rules.isEmpty) {
              return Center(
                child: Text(
                  'No rules created yet.',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              );
            }

            return ListView.separated(
              itemCount: rules.length,
              separatorBuilder: (_, __) => const Divider(height: 18),
              itemBuilder: (_, i) {
                final followUp = rules[i];
                final parentId = followUp.question.parentQuestionId!.trim();
                final triggerId =
                    (followUp.question.triggerOptionId ?? '').trim();

                final parentText =
                    (questionTextById[parentId] ?? '(Unknown)').trim();
                final triggerLabel =
                    (optionLabelById[triggerId] ?? '(Unknown)').trim();
                final followText = followUp.question.questionText.trim().isEmpty
                    ? '(Untitled)'
                    : followUp.question.questionText.trim();

                return LayoutBuilder(
                  builder: (context, c) {
                    final narrow = c.maxWidth < 520;

                    final info = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IF: $parentText',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'WHEN answer is: $triggerLabel',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'THEN show: $followText',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    );

                    final actions = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit rule',
                          onPressed: _saving
                              ? null
                              : () => _editRule(all: all, followUp: followUp),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          tooltip: 'Remove rule',
                          onPressed: _saving
                              ? null
                              : () => _removeRule(
                                    followUpDocId: followUp.question.id,
                                    allItems: all,
                                  ),
                          icon: const Icon(Icons.delete_outline),
                          color: Colors.red.shade600,
                        ),
                      ],
                    );

                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          info,
                          const SizedBox(height: 6),
                          Align(
                              alignment: Alignment.centerRight, child: actions),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: info),
                        const SizedBox(width: 12),
                        actions,
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      footer: Container(
        width: double.infinity,
        color: const Color(0xFFF8F8FB),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5F6368),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleEditResult {
  final String parentQuestionId;
  final String triggerOptionId;

  const _RuleEditResult({
    required this.parentQuestionId,
    required this.triggerOptionId,
  });
}

class AddRulesDialog extends StatefulWidget {
  final String questionSetId;
  final HostQuestionsController controller;

  const AddRulesDialog({
    super.key,
    required this.questionSetId,
    required this.controller,
  });

  @override
  State<AddRulesDialog> createState() => _AddRulesDialogState();
}

class _AddRulesDialogState extends State<AddRulesDialog> {
  String? _mainQuestionDocId;
  String? _triggerOptionId;
  String? _subQuestionDocId;

  bool _saving = false;

  bool _needsOptions(String type) =>
      type == 'multiple_choice' || type == 'checkboxes' || type == 'dropdown';

  @override
  Widget build(BuildContext context) {
    return _GfDialogFrame(
      title: 'Add rule',
      icon: Icons.add_link_rounded,
      disableClose: _saving,
      onClose: () => Navigator.pop(context),
      body: StreamBuilder<List<DemographicQuestionWithOptions>>(
        stream: widget.controller.streamQuestions(
          questionSetId: widget.questionSetId,
          includeConditional: true,
        ),
        builder: (context, snap) {
          if (snap.hasError) {
            return Text('Failed to load questions: ${snap.error}',
                style: GoogleFonts.poppins());
          }
          if (!snap.hasData) {
            return Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(width: 12),
                Text('Loading…', style: GoogleFonts.poppins()),
              ],
            );
          }

          final all = snap.data!;
          final base = all.where((x) {
            final p = x.question.parentQuestionId?.trim() ?? '';
            return p.isEmpty;
          }).toList();

          final mainCandidates = base
              .where((x) => _needsOptions(x.question.questionType))
              .toList();

          DemographicQuestionWithOptions? selectedMain;
          if (_mainQuestionDocId != null) {
            for (final q in mainCandidates) {
              if (q.question.id == _mainQuestionDocId) {
                selectedMain = q;
                break;
              }
            }
          }

          final subCandidates = base.where((x) {
            if (_mainQuestionDocId == null) return true;
            return x.question.id != _mainQuestionDocId;
          }).toList();

          final mainOptions =
              selectedMain?.options ?? const <DemographicQuestionOption>[];

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Main question',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _gfTextColor,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _mainQuestionDocId,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  for (final q in mainCandidates)
                    DropdownMenuItem(
                      value: q.question.id,
                      child: Text(
                        q.question.questionText.isEmpty
                            ? '(Untitled)'
                            : q.question.questionText,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                ],
                onChanged: (v) {
                  setState(() {
                    _mainQuestionDocId = v;
                    _triggerOptionId = null;
                  });
                },
              ),
              const SizedBox(height: 14),
              const Text(
                'When answer is',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _gfTextColor,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _triggerOptionId,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  for (final o in mainOptions)
                    DropdownMenuItem(
                      value: o.id,
                      child: Text(
                        o.label.isEmpty ? '(Option)' : o.label,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                ],
                onChanged: (_mainQuestionDocId == null)
                    ? null
                    : (v) => setState(() => _triggerOptionId = v),
              ),
              const SizedBox(height: 14),
              const Text(
                'Follow-up question (existing)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _gfTextColor,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _subQuestionDocId,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: [
                  for (final q in subCandidates)
                    DropdownMenuItem(
                      value: q.question.id,
                      child: Text(
                        q.question.questionText.isEmpty
                            ? '(Untitled)'
                            : q.question.questionText,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _subQuestionDocId = v),
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: Create questions freely first. Then use rules to attach one under a main question.',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
            ],
          );
        },
      ),
      footer: Container(
        width: double.infinity,
        color: const Color(0xFFF8F8FB),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5F6368),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _saving ? null : _saveRule,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gfPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save rule'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRule() async {
    if ((_mainQuestionDocId ?? '').isEmpty ||
        (_triggerOptionId ?? '').isEmpty ||
        (_subQuestionDocId ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select main question, answer option, and follow-up question.',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('demographicQuestions')
          .where('isDisabled', isEqualTo: false)
          .where('questionSetId', isEqualTo: widget.questionSetId)
          .where('parentQuestionId', isEqualTo: _mainQuestionDocId)
          .get();

      int maxOrder = 0;
      for (final d in snap.docs) {
        final v = d.data()['displayOrder'];
        final n = (v is num) ? v.toInt() : int.tryParse('$v') ?? 0;
        if (n > maxOrder) maxOrder = n;
      }

      await FirebaseFirestore.instance
          .collection('demographicQuestions')
          .doc(_subQuestionDocId)
          .update({
        'parentQuestionId': _mainQuestionDocId,
        'triggerOptionId': _triggerOptionId,
        'displayOrder': maxOrder + 1,
        'modifiedDate': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rule saved.', style: GoogleFonts.poppins())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to save rule: $e', style: GoogleFonts.poppins())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class EditRuleDialog extends StatefulWidget {
  final String questionSetId;
  final HostQuestionsController controller;
  final List<DemographicQuestionWithOptions> allItems;
  final DemographicQuestionWithOptions followUp;

  const EditRuleDialog({
    super.key,
    required this.questionSetId,
    required this.controller,
    required this.allItems,
    required this.followUp,
  });

  @override
  State<EditRuleDialog> createState() => _EditRuleDialogState();
}

class _EditRuleDialogState extends State<EditRuleDialog> {
  String? _mainQuestionDocId;
  String? _triggerOptionId;

  bool _needsOptions(String type) =>
      type == 'multiple_choice' || type == 'checkboxes' || type == 'dropdown';

  @override
  void initState() {
    super.initState();
    _mainQuestionDocId = widget.followUp.question.parentQuestionId?.trim();
    _triggerOptionId = widget.followUp.question.triggerOptionId?.trim();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.allItems.where((x) {
      final p = x.question.parentQuestionId?.trim() ?? '';
      return p.isEmpty;
    }).toList();

    final mainCandidates =
        base.where((x) => _needsOptions(x.question.questionType)).toList();

    DemographicQuestionWithOptions? selectedMain;
    if (_mainQuestionDocId != null) {
      for (final q in mainCandidates) {
        if (q.question.id == _mainQuestionDocId) {
          selectedMain = q;
          break;
        }
      }
    }

    final mainOptions =
        selectedMain?.options ?? const <DemographicQuestionOption>[];

    return _GfDialogFrame(
      title: 'Edit rule',
      icon: Icons.edit_outlined,
      disableClose: false,
      onClose: () => Navigator.pop(context, null),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Main question',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _gfTextColor,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _mainQuestionDocId,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              for (final q in mainCandidates)
                DropdownMenuItem(
                  value: q.question.id,
                  child: Text(
                    q.question.questionText.isEmpty
                        ? '(Untitled)'
                        : q.question.questionText,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(),
                  ),
                ),
            ],
            onChanged: (v) {
              setState(() {
                _mainQuestionDocId = v;
                _triggerOptionId = null;
              });
            },
          ),
          const SizedBox(height: 14),
          Text(
            'When answer is',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _gfTextColor,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _triggerOptionId,
            isExpanded: true,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              for (final o in mainOptions)
                DropdownMenuItem(
                  value: o.id,
                  child: Text(
                    o.label.isEmpty ? '(Option)' : o.label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(),
                  ),
                ),
            ],
            onChanged: (_mainQuestionDocId == null)
                ? null
                : (v) => setState(() => _triggerOptionId = v),
          ),
        ],
      ),
      footer: Container(
        width: double.infinity,
        color: const Color(0xFFF8F8FB),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5F6368),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if ((_mainQuestionDocId ?? '').isEmpty ||
                    (_triggerOptionId ?? '').isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Select main question and trigger option.',
                          style: GoogleFonts.poppins()),
                    ),
                  );
                  return;
                }

                Navigator.pop(
                  context,
                  _RuleEditResult(
                    parentQuestionId: _mainQuestionDocId!,
                    triggerOptionId: _triggerOptionId!,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _gfPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostRenderRow {
  final DemographicQuestionWithOptions item;
  final bool isSub;
  const _HostRenderRow({required this.item, required this.isSub});
}

// -----------------------------------------------------------------------------
// QUESTION CARD – updated styling
// -----------------------------------------------------------------------------

class _GoogleFormsQuestionCard extends StatelessWidget {
  final bool compact;
  final int index;
  final DemographicQuestionWithOptions item;

  final bool isActive;
  final VoidCallback onTap;

  final bool isFollowUp; // ✅ NEW
  final String? followUpTriggerLabel; // ✅ NEW
  final VoidCallback? onRemoveRule; // ✅ NEW

  final ValueChanged<String> onQuestionTextChanged;
  final ValueChanged<String> onQuestionTypeChanged;
  final ValueChanged<bool> onRequiredChanged;

  final VoidCallback onDelete;
  final ValueChanged<DemographicQuestionOption>? onRemoveOption;

  final VoidCallback? onAddOption;
  final void Function(DemographicQuestionOption opt, String newLabel)?
      onOptionLabelChanged;

  const _GoogleFormsQuestionCard({
    required this.compact,
    required this.index,
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.onQuestionTextChanged,
    required this.onQuestionTypeChanged,
    required this.onRequiredChanged,
    required this.onDelete,
    required this.onRemoveOption,
    required this.isFollowUp,
    this.followUpTriggerLabel,
    this.onRemoveRule,
    this.onAddOption,
    this.onOptionLabelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final q = item.question;
    final normalizedType = _QuestionTypeDropdown.normalizeType(q.questionType);

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
        padding:
            EdgeInsets.fromLTRB(compact ? 14 : 24, 16, compact ? 14 : 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: q.questionText,
                    onChanged: onQuestionTextChanged,
                    readOnly: !isActive,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Question',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: kAccent, width: 2),
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: compact ? 16 : 18,
                      fontWeight: FontWeight.w600,
                      color: kTextDark,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: compact ? 160 : 200,
                  child: isActive
                      ? _QuestionTypeDropdown(
                          currentType: normalizedType,
                          onChanged: onQuestionTypeChanged,
                        )
                      : _QuestionTypeDropdown.readonlyLabel(normalizedType),
                ),
              ],
            ),

            const SizedBox(height: 12),

            _QuestionBody(
              type: normalizedType,
              options: item.options,
              isActive: isActive,
              onRemoveOption: onRemoveOption,
              onOptionLabelChanged: onOptionLabelChanged,
              onAddOption: onAddOption,
            ),

            const SizedBox(height: 12),

            if (isActive)
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: Colors.black54,
                    tooltip: 'Delete question',
                    onPressed: onDelete,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Required',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kTextBody,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: q.isRequired,
                    onChanged: onRequiredChanged,
                    activeThumbColor: kAccent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Question type dropdown – only 5 types
// -----------------------------------------------------------------------------

class _QuestionTypeDropdown extends StatelessWidget {
  final String currentType;
  final ValueChanged<String> onChanged;

  const _QuestionTypeDropdown({
    required this.currentType,
    required this.onChanged,
  });

  static const _typeLabels = <String, String>{
    'short_answer': 'Short answer',
    'paragraph': 'Paragraph',
    'multiple_choice': 'Multiple choice',
    'checkboxes': 'Checkboxes',
    'dropdown': 'Dropdown',
  };

  static String normalizeType(String type) {
    if (_typeLabels.containsKey(type)) return type;
    return 'multiple_choice';
  }

  static String labelFor(String type) =>
      _typeLabels[normalizeType(type)] ?? 'Multiple choice';

  static Widget readonlyLabel(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: Text(
        labelFor(type),
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: kTextBody,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _typeLabels.entries.toList();
    final value = normalizeType(currentType);

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: [
        for (final e in entries)
          DropdownMenuItem(
            value: e.key,
            child: Text(
              e.value,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Question body (visual preview)
// -----------------------------------------------------------------------------

class _QuestionBody extends StatelessWidget {
  final String type;
  final List<DemographicQuestionOption> options;
  final bool isActive;
  final ValueChanged<DemographicQuestionOption>? onRemoveOption;
  final void Function(DemographicQuestionOption opt, String newLabel)?
      onOptionLabelChanged;
  final VoidCallback? onAddOption;

  const _QuestionBody({
    required this.type,
    required this.options,
    required this.isActive,
    this.onRemoveOption,
    this.onOptionLabelChanged,
    this.onAddOption,
  });

  final double _optionIconColumnWidth = 32;

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case 'short_answer':
        return _shortAnswer();
      case 'paragraph':
        return _paragraph();
      case 'checkboxes':
        return _choiceList(isCheckbox: true);
      case 'dropdown':
        return _dropdownPreview();
      case 'multiple_choice':
      default:
        return _choiceList(isCheckbox: false);
    }
  }

  Widget _shortAnswer() {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: Text(
        'Short answer text',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _paragraph() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        'Long answer text',
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// Multiple choice / checkbox options list
  /// Multiple choice / checkbox options list
  /// Multiple choice / checkbox options list
  /// Multiple choice / checkbox options list
  Widget _choiceList({required bool isCheckbox}) {
    if (options.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isActive ? 'No options yet. Click “Add option”.' : 'No options.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          if (isActive && onAddOption != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: InkWell(
                onTap: onAddOption,
                child: Row(
                  children: [
                    SizedBox(
                      width: _optionIconColumnWidth,
                      height: 22,
                      child: Center(
                        child: Icon(Icons.add, size: 16, color: kAccent),
                      ),
                    ),
                    Text(
                      'Add option',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    // ✅ Real options only
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final opt in options)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: _optionIconColumnWidth,
                  height: 24,
                  child: Center(
                    child: Icon(
                      isCheckbox
                          ? Icons.check_box_outline_blank
                          : Icons.radio_button_unchecked,
                      size: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    height: 24,
                    child: Center(
                      child: TextFormField(
                        initialValue: opt.label.trim(),
                        readOnly: !isActive || opt.id.isEmpty,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: (isActive && opt.id.isNotEmpty)
                              ? const UnderlineInputBorder(
                                  borderSide:
                                      BorderSide(color: kAccent, width: 2),
                                )
                              : InputBorder.none,
                        ),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: kTextDark,
                        ),
                        onChanged: (value) {
                          if (!isActive ||
                              onOptionLabelChanged == null ||
                              opt.id.isEmpty) return;
                          onOptionLabelChanged!(opt, value.trim());
                        },
                      ),
                    ),
                  ),
                ),
                if (isActive && onRemoveOption != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.close,
                          size: 18, color: Colors.black54),
                      onPressed: () => onRemoveOption!(opt),
                    ),
                  ),
              ],
            ),
          ),
        if (isActive && onAddOption != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: onAddOption,
              child: Row(
                children: [
                  SizedBox(
                    width: _optionIconColumnWidth,
                    height: 22,
                    child: Center(
                      child: Icon(Icons.add, size: 16, color: kAccent),
                    ),
                  ),
                  Text(
                    'Add option',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: kAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Dropdown preview – real clickable dropdown using the options
  /// Dropdown preview – real clickable dropdown using the options
  Widget _dropdownPreview() {
    final labels = options.isNotEmpty
        ? options.map((o) => o.label).toList()
        : <String>['Option 1'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kBorder),
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
            for (final label in labels)
              DropdownMenuItem<String>(
                value: label,
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kTextDark,
                  ),
                ),
              ),
          ],
          // Preview only – selection isn't persisted here
          onChanged: isActive ? (_) {} : null,
        ),
        if (isActive && onAddOption != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: TextButton.icon(
              onPressed: onAddOption,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.add, size: 18, color: kAccent),
              label: Text(
                'Add option',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kAccent,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

double _dialogWidth(BuildContext context, {double desktopMax = 720}) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 600) return math.max(280, w - 32);
  return desktopMax;
}

class _GfDialogFrame extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool disableClose;
  final VoidCallback onClose;
  final Widget body;
  final Widget footer;

  const _GfDialogFrame({
    required this.title,
    required this.icon,
    required this.disableClose,
    required this.onClose,
    required this.body,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final dialogW = _dialogWidth(context, desktopMax: 720);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: dialogW),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ TOP PURPLE HEADER (same as AddQuestionDialog)
                Container(
                  width: double.infinity,
                  color: _gfPurple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: disableClose ? null : onClose,
                      ),
                    ],
                  ),
                ),

                // ✅ BODY
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: body,
                  ),
                ),

                // ✅ FOOTER
                footer,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
