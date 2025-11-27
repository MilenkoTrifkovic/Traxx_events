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
  const HostQuestionsScreen({super.key});

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

  Future<void> _handleAddQuestion() async {
    // TODO: plug real companyId / eventId if needed
    const companyId = '';
    const eventId = '';

    _pendingFocusNew = true;

    await _controller.createQuestionWithOptions(
      questionText: '',
      questionCategory: 'general',
      questionType: 'multiple_choice',
      isRequired: false,
      companyId: companyId,
      eventId: eventId,
      options: [
        NewOptionInput(label: 'Option 1', value: 'option_1'),
        NewOptionInput(label: 'Option 2', value: 'option_2'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // We draw our own Google Forms style background; outer wrapper handles scroll.
    return Container(
      color: _gfBackground,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          final formContent = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFormHeaderCard(context),
                  const SizedBox(height: 12),
                  _buildQuestionsStream(),
                ],
              ),
            ),
          );

          return Stack(
            children: [
              formContent,
              if (isWide)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 40),
                      child: _GoogleFormsSideToolbar(
                        onAddQuestionTapped: _handleAddQuestion,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
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
      stream: _controller.streamQuestions(),
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
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            final item = questions.removeAt(oldIndex);
            questions.insert(newIndex, item);

            for (int i = 0; i < questions.length; i++) {
              final q = questions[i].question;
              _controller.updateQuestion(
                questionDocId: q.id,
                data: {'displayOrder': i + 1},
              );
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
                onTap: () => _setActiveQuestion(item.question.id),
                onQuestionTextChanged: (text) {
                  _debouncedUpdateQuestion(
                    item.question.id,
                    {'questionText': text},
                  );
                },
                onQuestionTypeChanged: (type) {
                  _controller.updateQuestion(
                    questionDocId: item.question.id,
                    data: {'questionType': type},
                  );
                },
                onRequiredChanged: (required) {
                  _controller.updateQuestion(
                    questionDocId: item.question.id,
                    data: {'isRequired': required},
                  );
                },
                onDelete: () {
                  _controller.deleteQuestionWithOptions(item.question.id);
                },
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
    return Column(
      children: List.generate(
        3,
        (index) => TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 500 + index * 120),
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: child,
          ),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: [
                    AppColors.skeletonBase,
                    AppColors.skeletonHighlight,
                    AppColors.skeletonBase,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
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
// RIGHT-SIDE GOOGLE FORMS TOOLBAR
// -----------------------------------------------------------------------------

class _GoogleFormsSideToolbar extends StatelessWidget {
  final Future<void> Function() onAddQuestionTapped;

  const _GoogleFormsSideToolbar({
    required this.onAddQuestionTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(28),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _toolbarIcon(
              icon: Icons.add_circle_outline,
              tooltip: 'Add question',
              onTap: onAddQuestionTapped,
            ),
            _toolbarIcon(
              icon: Icons.description_outlined,
              tooltip: 'Add title and description',
            ),
            _toolbarIcon(
              icon: Icons.image_outlined,
              tooltip: 'Add image',
            ),
            _toolbarIcon(
              icon: Icons.smart_display_outlined,
              tooltip: 'Add video',
            ),
            _toolbarIcon(
              icon: Icons.view_agenda_outlined,
              tooltip: 'Add section',
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolbarIcon({
    required IconData icon,
    required String tooltip,
    Future<void> Function()? onTap,
  }) {
    return IconButton(
      icon: Icon(icon, size: 24),
      tooltip: tooltip,
      color: _gfPurple,
      onPressed: onTap == null ? null : () => onTap(),
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

  const _GoogleFormsQuestionCard({
    required this.index, // NEW
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.onQuestionTextChanged,
    required this.onQuestionTypeChanged,
    required this.onRequiredChanged,
    required this.onDelete,
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

  const _QuestionBody({
    required this.type,
    required this.options,
    required this.isActive,
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
                  if (isActive) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.close, size: 18, color: Colors.black45),
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
