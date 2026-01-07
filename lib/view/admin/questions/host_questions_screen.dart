// lib/views/host_questions_screen.dart
import 'dart:async';
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

  /*  void _debouncedUpdateQuestion(
    String questionDocId,
    Map<String, dynamic> data,
  ) {
    final key = questionDocId;
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(const Duration(milliseconds: 400), () {
      _controller.updateQuestion(questionDocId: questionDocId, data: data);
    });
  } */
  void _debouncedUpdateQuestion(
    String questionDocId,
    Map<String, dynamic> data,
  ) {
    final key = questionDocId;
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(const Duration(milliseconds: 400), () {
      _controller.updateQuestion(questionDocId: questionDocId, data: data);
    });
  }

  void _debouncedUpdateOption(
    String optionDocId,
    Map<String, dynamic> data,
  ) {
    final key = 'opt_$optionDocId';
    _optionDebounceTimers[key]?.cancel();
    _optionDebounceTimers[key] = Timer(const Duration(milliseconds: 400), () {
      _controller.updateOption(optionDocId: optionDocId, data: data);
    });
  }

  Future<void> _addOption(DemographicQuestionWithOptions item) async {
    _setProcessing(true);
    try {
      // displayOrder: last + 1
      final nextOrder =
          item.options.isNotEmpty ? (item.options.last.displayOrder + 1) : 1;

      final newOpt = await _controller.createOption(
        questionId: item.question.questionId,
        displayOrder: nextOrder,
      );

      if (!mounted) return;

      // UI update is actually optional now because streamQuestions
      // will push a new snapshot, but this makes it feel instant.
      setState(() {
        item.options.add(newOpt);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add option: $e',
            style: GoogleFonts.poppins(),
          ),
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
        title: Text(
          'Delete option?',
          style: GoogleFonts.poppins(),
        ),
        content: Text(
          'Do you want to delete "${opt.label}"?',
          style: GoogleFonts.poppins(),
        ),
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
      setState(() {
        item.options.removeWhere((o) => o.id == opt.id);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete option: $e',
            style: GoogleFonts.poppins(),
          ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update type: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update required: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        title: Text(
          'Delete question?',
          style: GoogleFonts.poppins(),
        ),
        content: Text(
          'This will permanently delete the question and its options.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _setProcessing(true);
    try {
      await _controller.deleteQuestionWithOptions(item.question.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to delete question: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> _handleAddQuestion() async {
    _pendingFocusNew = true;

    final bool? created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddQuestionDialog(
        questionSetId: widget.questionSetId,
      ),
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

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final viewportH = MediaQuery.of(context).size.height;
    final listH = (viewportH - 360).clamp(320.0, 900.0); // ✅ safe height

    return DefaultTextStyle(
      style: GoogleFonts.poppins(),
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: _gfBackground)),
          Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeaderWithAddButton(context),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            'Click on a question to edit',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ✅ fixed-height scroll area (no Expanded)
                        SizedBox(
                          height: listH,
                          child: _buildQuestionsStream(),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: _gfBackground.withOpacity(0.35),
                child: const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 3, color: _gfPurple),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER CARD + BUTTON ROW
  // ---------------------------------------------------------------------------

  Widget _buildHeaderWithAddButton(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildFormHeaderCard()),
        const SizedBox(width: 16),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handleAddQuestion,
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
            child: const Text('Add Question'),
          ),
        ),
      ],
    );
  }

  Widget _buildFormHeaderCard() {
    final title = _setTitle.isEmpty ? 'Untitled form' : _setTitle;
    final description =
        _setDescription.isEmpty ? 'Form description' : _setDescription;

    return Card(
      color: Colors.white, // pure white like Forms
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
          // Colored top border like Google Forms
          Container(
            height: 6,
            decoration: const BoxDecoration(
              color: kGfPurple,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kTextDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUESTIONS STREAM
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // QUESTIONS STREAM
  // ---------------------------------------------------------------------------

  Widget _buildQuestionsStream() {
    return StreamBuilder<List<DemographicQuestionWithOptions>>(
      stream: _controller.streamQuestions(
        questionSetId: widget.questionSetId,
        includeConditional: true,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final err = snapshot.error;
          if (kDebugMode) {
            debugPrint('🔥 HostQuestionsScreen error: $err');
          }
          return _buildErrorState(err.toString());
        }

        // ✅ IMPORTANT: show loader until first emission arrives
        if (!snapshot.hasData) {
          return _buildLoadingSkeleton();
        }

        final items = snapshot.data!;

        // Once we HAVE data (even empty), show empty state correctly
        if (items.isEmpty) return _buildEmptyState();

        final all = List<DemographicQuestionWithOptions>.from(items);

        final base = all.where((x) {
          final p = x.question.parentQuestionId?.trim() ?? '';
          return p.isEmpty;
        }).toList();

        final subs = all.where((x) {
          final p = x.question.parentQuestionId?.trim() ?? '';
          return p.isNotEmpty;
        }).toList();

// group subs by parentQuestionId
        final Map<String, List<DemographicQuestionWithOptions>> subsByParent =
            {};
        for (final s in subs) {
          final parentId = s.question.parentQuestionId!.trim();
          subsByParent.putIfAbsent(parentId, () => []).add(s);
        }

// sort subs by displayOrder
        for (final entry in subsByParent.entries) {
          entry.value.sort((a, b) =>
              a.question.displayOrder.compareTo(b.question.displayOrder));
        }

// Build a "render list": base question + its subs underneath
        final renderList = <_HostRenderRow>[];

        for (final b in base) {
          renderList.add(_HostRenderRow(item: b, isSub: false));
          final children = subsByParent[b.question.questionId] ?? const [];
          for (final c in children) {
            renderList.add(_HostRenderRow(item: c, isSub: true));
          }
        }

        if (_pendingFocusNew && all.isNotEmpty) {
          _pendingFocusNew = false;
          final newId = all.last.question.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _setActiveQuestion(newId);
          });
        }

        return Scrollbar(
            thumbVisibility: true,
            child: ReorderableListView.builder(
              scrollController: _listScrollCtrl,
              key: const PageStorageKey('questions_reorderable_list'),
              buildDefaultDragHandles: false,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex--;
                final item = all.removeAt(oldIndex);
                all.insert(newIndex, item);

                _setProcessing(true);
                try {
                  await Future.wait([
                    for (int i = 0; i < all.length; i++)
                      _controller.updateQuestion(
                        questionDocId: all[i].question.id,
                        data: {'displayOrder': i + 1},
                      ),
                  ]);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to reorder questions: $e',
                            style: GoogleFonts.poppins()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  _setProcessing(false);
                }
              },
              itemCount: renderList.length,
              itemBuilder: (context, index) {
                final row = renderList[index];
                final item = row.item;

                return Padding(
                  key: ValueKey(item.question.id),
                  padding: EdgeInsets.only(
                    bottom: 12,
                    left: row.isSub ? 28 : 0, // ✅ indent subs
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (row.isSub)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.06),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Follow-up',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Shown when option: ${item.question.triggerOptionId ?? ""}',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                      fontSize: 12, color: Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        ),
                      _GoogleFormsQuestionCard(
                        index:
                            index, // reorder will be disabled anyway in grouped view
                        item: item,
                        isActive: item.question.id == _activeQuestionId,
                        onTap: () => _setActiveQuestion(item.question.id),
                        onQuestionTextChanged: (text) =>
                            _debouncedUpdateQuestion(
                          item.question.id,
                          {'questionText': text},
                        ),
                        onQuestionTypeChanged: (type) =>
                            _updateQuestionType(item.question.id, type),
                        onRequiredChanged: (required) =>
                            _updateRequired(item.question.id, required),
                        onDelete: () => _confirmDeleteQuestion(item),
                        onRemoveOption: (opt) => _removeOption(item, opt),
                        onAddOption: () => _addOption(item),
                        onOptionLabelChanged: (opt, newLabel) {
                          if (opt.id.isEmpty) return;
                          _debouncedUpdateOption(opt.id, {'label': newLabel});
                        },
                      ),
                    ],
                  ),
                );
              },
            ));
      },
    );
  }

  // ---------------------------------------------------------------------------
  // STATES
  // ---------------------------------------------------------------------------

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
        color: Colors.white, // ❗️Make sure this is white, not lavender
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 48,
                color: kGfPurple,
              ),
              SizedBox(height: 16),
              Text(
                'No questions yet',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: kTextDark,
                ),
              ),
              SizedBox(height: 6),
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

// -----------------------------------------------------------------------------
// QUESTION CARD – updated styling
// -----------------------------------------------------------------------------

class _GoogleFormsQuestionCard extends StatelessWidget {
  final int index;
  final DemographicQuestionWithOptions item;
  final bool isActive;
  final VoidCallback onTap;
  final ValueChanged<String> onQuestionTextChanged;
  final ValueChanged<String> onQuestionTypeChanged;
  final ValueChanged<bool> onRequiredChanged;
  final VoidCallback onDelete;
  final ValueChanged<DemographicQuestionOption>? onRemoveOption;

  // NEW:
  final VoidCallback? onAddOption;
  final void Function(DemographicQuestionOption opt, String newLabel)?
      onOptionLabelChanged;

  const _GoogleFormsQuestionCard({
    required this.index,
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.onQuestionTextChanged,
    required this.onQuestionTypeChanged,
    required this.onRequiredChanged,
    required this.onDelete,
    required this.onRemoveOption,
    this.onAddOption, // NEW
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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            // Center(
            //   child: ReorderableDragStartListener(
            //     index: index,
            //     child: Icon(
            //       Icons.drag_indicator_rounded,
            //       size: 20,
            //       color: Colors.grey.shade500,
            //     ),
            //   ),
            // ),
            // const SizedBox(height: 8),

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
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: kAccent,
                          width: 2,
                        ),
                      ),
                    ),
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
    final hasRealOptions = options.isNotEmpty;

    final list = hasRealOptions
        ? options
        : [
            DemographicQuestionOption(
              id: '',
              questionId: '',
              label: 'Option 1',
              value: 'option_1',
              optionType: 'choice',
              requiresFreeText: false,
              isDisabled: false,
              displayOrder: 1,
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final opt in list)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- ICON COLUMN (fixed width) ---
                SizedBox(
                  width: _optionIconColumnWidth,
                  height: 24, // match row height for perfect centering
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

                // --- LABEL TEXT (perfectly centered vertically) ---
                Expanded(
                  child: SizedBox(
                    height: 24,
                    child: Center(
                      child: TextFormField(
                        initialValue: opt.label.trim(),
                        readOnly:
                            !isActive || !hasRealOptions || opt.id.isEmpty,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero, // FIXED alignment
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder:
                              (isActive && hasRealOptions && opt.id.isNotEmpty)
                                  ? const UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: kAccent,
                                        width: 2,
                                      ),
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
                              !hasRealOptions ||
                              onOptionLabelChanged == null ||
                              opt.id.isEmpty) {
                            return;
                          }

                          onOptionLabelChanged!(opt, value.trim());
                        },
                      ),
                    ),
                  ),
                ),

                // --- DELETE ---
                if (isActive && hasRealOptions && onRemoveOption != null)
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

        // --- ADD OPTION ROW ---
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

class _HostRenderRow {
  final DemographicQuestionWithOptions item;
  final bool isSub;
  const _HostRenderRow({required this.item, required this.isSub});
}
