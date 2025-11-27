// lib/views/host_questions_screen.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/controller/admin_controllers/host_questions_controller.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/layout/headers/widgets/add_question_dialog.dart';
import 'package:traxx_wepapp/models/host_questions_option.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

// Google Forms colors
// Google Forms colors
const Color _gfPurple = Color(0xFF673AB7); // top bar + accents
const Color _gfBackground = Color(0xFFF4F0FB); // light lavender background
const Color _gfTextColor = Color(0xFF202124); // main text color

class HostQuestionsScreen extends StatefulWidget {
  final String questionSetId;
  final String questionSetTitle;

  const HostQuestionsScreen({
    super.key,
    required this.questionSetId,
    required this.questionSetTitle,
  });

  @override
  State<HostQuestionsScreen> createState() => _HostQuestionsScreenState();
}

class _HostQuestionsScreenState extends State<HostQuestionsScreen>
    with SingleTickerProviderStateMixin {
  late final HostQuestionsController _controller;

  /// Which question is currently focused / “editing”.
  String? _activeQuestionId;

  /// Simple debounce map so we don’t spam Firestore while typing.
  final Map<String, Timer> _debounceTimers = {};

  /// When true, after a new question is added we want to focus it.
  bool _pendingFocusNew = false;

  bool _isProcessing = false; // 👈 NEW

  void _setProcessing(bool value) {
    if (!mounted) return;
    setState(() => _isProcessing = value);
  }

  @override
  void initState() {
    super.initState();
    _controller =
        HostQuestionsController(firestore: FirebaseFirestore.instance);
  }

  @override
  void dispose() {
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _setActiveQuestion(String id) {
    if (_activeQuestionId == id) return;
    setState(() => _activeQuestionId = id);
  }

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

  Future<void> _removeOption(DemographicQuestionOption opt) async {
    // Confirm dialog with a loader on the Delete button
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete option?'),
              content: Text(
                'Do you want to delete "${opt.label}"?',
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setState(() => isDeleting = true);
                          try {
                            await _controller.deleteOption(opt.id);
                            // close dialog and return true
                            Navigator.of(dialogContext).pop(true);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to delete option: $e',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            Navigator.of(dialogContext).pop(false);
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.red),
                          ),
                        )
                      : const Text('Delete'),
                ),
              ],
            );
          },
        );
      },
    );

    // If user cancelled OR delete failed, do nothing here
    if (confirmed != true) return;
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
            content: Text('Failed to update type: $e'),
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
            content: Text('Failed to update required: $e'),
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
        title: const Text('Delete question?'),
        content: const Text(
          'This will permanently delete the question and its options.',
        ),
        actions: [
          TextButton(
            // IMPORTANT: use dialogContext, not the outer context
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
            content: Text('Failed to delete question: $e'),
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
      // brief overlay while Firestore sends new snapshot
      _setProcessing(true);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _setProcessing(false);
      });
    } else {
      _pendingFocusNew = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Container(
      color: _gfBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final formContent = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  _buildHeaderWithAddButton(
                      context), // 👈 new row with card + button
                  const SizedBox(height: 12),
                  _buildQuestionsStream(),
                ],
              ),
            ),
          );

          return formContent;
        },
      ),
    );

    return Stack(
      children: [
        body,
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.05),
              child: const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _gfPurple,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER CARD – Form title / description (Google Forms style)
  // ---------------------------------------------------------------------------

  Widget _buildFormHeaderCard(BuildContext context) {
    return Card(
      color: Colors.white, // NEW
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: AppColors.borderSubtle),
      ),

      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border(
            top: BorderSide(
              color: _gfPurple, // Google Forms top colored bar
              width: 8,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            // Title
            TextField(
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Untitled form',
              ),
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 32,
                fontWeight: FontWeight.w400,
                color: _gfTextColor,
                letterSpacing: 0.1,
              ),
            ),
            SizedBox(height: 8),
            // Description
            TextField(
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Form description',
              ),
              maxLines: 3,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // QUESTIONS STREAM
  // ---------------------------------------------------------------------------

  Widget _buildQuestionsStream() {
    return StreamBuilder<List<DemographicQuestionWithOptions>>(
      stream: _controller.streamQuestions(
        questionSetId: widget.questionSetId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final err = snapshot.error;
          if (kDebugMode) {
            if (err is FirebaseException) {
              print(
                  '🔥 Firestore error in HostQuestionsScreen: ${err.code} – ${err.message}');
              print('🔥 Full error: $err');
            } else {
              print('🔥 Unknown error in HostQuestionsScreen: $err');
            }
          }
          return _buildErrorState(context, err.toString());
        }

        if (!snapshot.hasData) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingSkeleton(context);
          }
          return _buildEmptyState(context);
        }

        final items = snapshot.data!;
        if (items.isEmpty) {
          return _buildEmptyState(context);
        }

        final questions = List<DemographicQuestionWithOptions>.from(items);

        // If we just added a new question, focus the last one.
        if (_pendingFocusNew && questions.isNotEmpty) {
          _pendingFocusNew = false;
          final newId = questions.last.question.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _setActiveQuestion(newId);
          });
        }

        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          key: const PageStorageKey('questions_reorderable_list'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: questions.length,
          onReorder: (oldIndex, newIndex) async {
            if (newIndex > oldIndex) newIndex--;
            final item = questions.removeAt(oldIndex);
            questions.insert(newIndex, item);

            _setProcessing(true);
            try {
              await Future.wait([
                for (int i = 0; i < questions.length; i++)
                  _controller.updateQuestion(
                    questionDocId: questions[i].question.id,
                    data: {'displayOrder': i + 1},
                  ),
              ]);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to reorder questions: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } finally {
              _setProcessing(false);
            }
          },
          itemBuilder: (context, index) {
            final item = questions[index];
            return Padding(
              key: ValueKey(item.question.id),
              padding: const EdgeInsets.only(bottom: 12),
              child: _GoogleFormsQuestionCard(
                index: index,
                item: item,
                isActive: item.question.id == _activeQuestionId,
                onRemoveOption: (opt) => _removeOption(opt),
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
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Loading / Empty / Error
  // ---------------------------------------------------------------------------

  Widget _buildLoadingSkeleton(BuildContext context) {
    return SizedBox(
      height: 300, // give it some space under the header
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: _gfPurple, // violet loader
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + 0.05 * value,
            child: child,
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.help_outline_rounded,
                size: 48,
                color: _gfPurple,
              ),
              const SizedBox(height: 16),
              AppText.styledBodyLarge(
                context,
                'No questions yet',
                color: Colors.black,
              ),
              const SizedBox(height: 6),
              AppText.styledBodySmall(
                context,
                'Start by adding your first question using the + button on the right.',
                color: AppColors.secondary,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithAddButton(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Untitled form card takes all available space
        Expanded(
          child: _buildFormHeaderCard(context),
        ),
        const SizedBox(width: 12),
        // Purple "Add Question" button
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 0, 0),
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _isProcessing ? null : _handleAddQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gfPurple,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter', // or 'Roboto' if you prefer
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              /* icon: const Icon(Icons.add, size: 18), */
              label: const Text('Add Question'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: AppText.styledBodySmall(
                context,
                'Failed to load questions: $error',
                color: Colors.red.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// -----------------------------------------------------------------------------
// QUESTION CARD – Google Forms look & feel
// -----------------------------------------------------------------------------

class _GoogleFormsQuestionCard extends StatelessWidget {
  final int index; // NEW
  final DemographicQuestionWithOptions item;
  final bool isActive;
  final VoidCallback onTap;
  final ValueChanged<String> onQuestionTextChanged;
  final ValueChanged<String> onQuestionTypeChanged;
  final ValueChanged<bool> onRequiredChanged;
  final VoidCallback onDelete;
  final ValueChanged<DemographicQuestionOption>? onRemoveOption;

  const _GoogleFormsQuestionCard({
    required this.index, // NEW
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.onQuestionTextChanged,
    required this.onQuestionTypeChanged,
    required this.onRequiredChanged,
    required this.onDelete,
    required this.onRemoveOption,
  });

  @override
  Widget build(BuildContext context) {
    final q = item.question;

    // Only these 5 types are supported now
    final normalizedType = _QuestionTypeDropdown.normalizeType(q.questionType);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? _gfPurple : AppColors.borderSubtle,
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                offset: const Offset(0, 2),
                blurRadius: 6,
              ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_indicator,
                  size: 20,
                  color: AppColors.borderHover,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Header row: question text + type dropdown/label
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text (bigger & slightly bolder)
                Expanded(
                  child: TextFormField(
                    initialValue: q.questionText,
                    onChanged: onQuestionTextChanged,
                    readOnly: !isActive,
                    minLines: 1,
                    maxLines: 2,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Question',
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.transparent),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: _gfPurple,
                          width: 2,
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _gfTextColor,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                SizedBox(
                  width: 190,
                  child: isActive
                      ? _QuestionTypeDropdown(
                          currentType: normalizedType,
                          onChanged: onQuestionTypeChanged,
                        )
                      : _QuestionTypeDropdown.readonlyLabel(normalizedType),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Question body based on type
            _QuestionBody(
              type: normalizedType,
              options: item.options,
              isActive: isActive,
              onRemoveOption: onRemoveOption,
            ),

            const SizedBox(height: 12),

            // Bottom toolbar: only show while active (Required + delete)
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
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: q.isRequired,
                    onChanged: onRequiredChanged,
                    activeColor: _gfPurple,
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

  // Only these 5 types
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
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.transparent),
        color: Colors.transparent,
      ),
      child: Text(
        labelFor(type),
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: _gfTextColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _typeLabels.entries.toList();
    final value = normalizeType(currentType);

    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: [
        for (final e in entries)
          DropdownMenuItem(
            value: e.key,
            child: Text(e.value, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}

// -----------------------------------------------------------------------------
// Question body for different types (visual only, like Google Forms)
// -----------------------------------------------------------------------------

class _QuestionBody extends StatelessWidget {
  final String type;
  final List<DemographicQuestionOption> options;
  final bool isActive;
  final ValueChanged<DemographicQuestionOption>? onRemoveOption;

  const _QuestionBody({
    required this.type,
    required this.options,
    required this.isActive,
    this.onRemoveOption,
  });

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
    return Container(
      padding: const EdgeInsets.only(top: 2, bottom: 4),
      child: const Text(
        'Short answer text',
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          height: 1.2,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _paragraph() {
    return Container(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: const Text(
        'Long answer text',
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Colors.black54,
        ),
      ),
    );
  }

  /// Multiple choice / checkboxes list.
  Widget _choiceList({required bool isCheckbox}) {
    final baseOptions = options.isNotEmpty
        ? options
        : [
            DemographicQuestionOption(
              id: '1',
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
        for (final opt in baseOptions)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SizedBox(
              height: 38, // fixed height for icon + text
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    isCheckbox
                        ? Icons.check_box_outline_blank
                        : Icons.radio_button_unchecked,
                    size: 15,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      readOnly: !isActive,
                      controller: TextEditingController(text: opt.label),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: _gfPurple,
                            width: 2,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.8, // keeps baseline near center
                        color: _gfTextColor,
                      ),
                    ),
                  ),
                  if (isActive && onRemoveOption != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onRemoveOption!(opt),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
/*         const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              isCheckbox
                  ? Icons.check_box_outline_blank
                  : Icons.radio_button_unchecked,
              size: 15,
            ),
            const SizedBox(width: 12),
            const Text(
              'Add option',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'or',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'add "Other"',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: Colors.blue,
              ),
            ),
          ],
        ),
 */
      ],
    );
  }

  Widget _dropdownPreview() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black26),
      ),
      child: Row(
        children: [
          Text(
            options.isNotEmpty ? options.first.label : 'Option 1',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _gfTextColor,
            ),
          ),
          const Spacer(),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }
}
