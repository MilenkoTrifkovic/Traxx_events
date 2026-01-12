import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/models/host_questions.dart';
import 'package:traxx_wepapp/models/host_questions_option.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

/// Widget for rendering a single demographic question input field with proper type handling
class DemographicQuestionWidget extends StatefulWidget {
  final DemographicQuestion question;
  final dynamic currentAnswer;
  final Function(dynamic) onAnswerChanged;

  const DemographicQuestionWidget({
    super.key,
    required this.question,
    required this.currentAnswer,
    required this.onAnswerChanged,
  });

  @override
  State<DemographicQuestionWidget> createState() => _DemographicQuestionWidgetState();
}

class _DemographicQuestionWidgetState extends State<DemographicQuestionWidget> {
  List<DemographicQuestionOption> _options = [];
  bool _isLoadingOptions = false;
  final Map<String, TextEditingController> _freeTextControllers = {};
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.currentAnswer is String ? widget.currentAnswer : '',
    );
    _loadOptions();
  }

  @override
  void dispose() {
    _textController.dispose();
    for (var controller in _freeTextControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOptions() async {
    // Only load options for questions that need them
    if (!_needsOptions()) return;

    setState(() => _isLoadingOptions = true);

    try {
      final optionsSnapshot = await FirebaseFirestore.instance
          .collection('demographicQuestionOptions')
          .where('questionId', isEqualTo: widget.question.questionId)
          .where('isDisabled', isEqualTo: false)
          .orderBy('displayOrder')
          .get();

      setState(() {
        _options = optionsSnapshot.docs
            .map((doc) => DemographicQuestionOption.fromDoc(doc))
            .toList();
      });
    } catch (e) {
      print('❌ Error loading options for question ${widget.question.questionId}: $e');
    } finally {
      setState(() => _isLoadingOptions = false);
    }
  }

  bool _needsOptions() {
    return widget.question.questionType == 'multiple_choice' ||
        widget.question.questionType == 'checkboxes' ||
        widget.question.questionType == 'dropdown';
  }

  TextEditingController _getFreeTextController(String key) {
    if (!_freeTextControllers.containsKey(key)) {
      // Check if there's existing free text in the answer
      String initialText = '';
      if (widget.currentAnswer is Map && widget.currentAnswer['freeText'] != null) {
        initialText = widget.currentAnswer['freeText'];
      } else if (widget.currentAnswer is List) {
        final item = (widget.currentAnswer as List).firstWhere(
          (x) => x is Map && x['value'] == key.split('__').last,
          orElse: () => null,
        );
        if (item != null && item['freeText'] != null) {
          initialText = item['freeText'];
        }
      }
      _freeTextControllers[key] = TextEditingController(text: initialText);
    }
    return _freeTextControllers[key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question text
          Row(
            children: [
              Expanded(
                child: AppText.styledLabelLarge(
                  context,
                  widget.question.questionText,
                  weight: FontWeight.w600,
                ),
              ),
              if (widget.question.isRequired)
                AppText.styledLabelLarge(
                  context,
                  '*',
                  color: AppColors.inputError,
                  weight: FontWeight.bold,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Input field based on question type
          _isLoadingOptions 
              ? const SizedBox(
                  height: 44,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ) 
              : _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    switch (widget.question.questionType) {
      case 'short_answer':
        return TextField(
          controller: _textController,
          onChanged: widget.onAnswerChanged,
          decoration: InputDecoration(
            hintText: 'Enter your answer',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.primaryAccent, width: 1.6),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          maxLines: 1,
        );

      case 'paragraph':
        return TextField(
          controller: _textController,
          onChanged: widget.onAnswerChanged,
          decoration: InputDecoration(
            hintText: 'Enter your answer',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.primaryAccent, width: 1.6),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
          maxLines: 5,
        );

      case 'multiple_choice':
        return _buildRadioGroup();

      case 'checkboxes':
        return _buildCheckboxGroup();

      case 'dropdown':
        return _buildDropdown();

      default:
        return TextField(
          controller: _textController,
          onChanged: widget.onAnswerChanged,
          decoration: InputDecoration(
            hintText: 'Enter your answer',
            hintStyle: TextStyle(color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.primaryAccent, width: 1.6),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        );
    }
  }

  Widget _buildRadioGroup() {
    if (_options.isEmpty) {
      return AppText.styledBodyMedium(
        context,
        'No options available',
        color: AppColors.textMuted,
      );
    }

    final selectedValue = widget.currentAnswer is Map
        ? widget.currentAnswer['value']
        : widget.currentAnswer;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._options.map((option) {
          final isSelected = selectedValue == option.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioListTile<String>(
                title: AppText.styledBodyMedium(context, option.label),
                value: option.value,
                groupValue: selectedValue,
                activeColor: AppColors.primaryAccent,
                onChanged: (value) {
                  if (value == null) return;
                  if (option.requiresFreeText) {
                    final ctrlKey = '${widget.question.questionId}__${option.value}';
                    _getFreeTextController(ctrlKey);
                    widget.onAnswerChanged({
                      'value': option.value,
                      'label': option.label,
                      'requiresFreeText': true,
                      'freeText': _freeTextControllers[ctrlKey]?.text ?? '',
                    });
                  } else {
                    widget.onAnswerChanged(option.value);
                  }
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
              ),
              if (option.requiresFreeText && isSelected)
                Padding(
                  padding: const EdgeInsets.only(left: 32, bottom: 8, top: 4),
                  child: TextField(
                    controller: _getFreeTextController(
                      '${widget.question.questionId}__${option.value}',
                    ),
                    decoration: InputDecoration(
                      labelText: 'Please specify',
                      labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: AppColors.borderSubtle),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: AppColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: AppColors.primaryAccent, width: 1.6),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                    onChanged: (text) {
                      widget.onAnswerChanged({
                        'value': option.value,
                        'label': option.label,
                        'requiresFreeText': true,
                        'freeText': text,
                      });
                    },
                  ),
                ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildCheckboxGroup() {
    if (_options.isEmpty) {
      return AppText.styledBodyMedium(
        context,
        'No options available',
        color: AppColors.textMuted,
      );
    }

    final selected = (widget.currentAnswer as List?)?.cast<Map<String, dynamic>>() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _options.map((option) {
        final isChecked = selected.any((x) => x['value'] == option.value);
        final ctrlKey = '${widget.question.questionId}__${option.value}';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              title: AppText.styledBodyMedium(context, option.label),
              value: isChecked,
              activeColor: AppColors.primaryAccent,
              onChanged: (checked) {
                final next = List<Map<String, dynamic>>.from(selected);
                if (checked == true) {
                  if (option.requiresFreeText) {
                    _getFreeTextController(ctrlKey);
                    next.add({
                      'value': option.value,
                      'label': option.label,
                      'requiresFreeText': true,
                      'freeText': _freeTextControllers[ctrlKey]?.text ?? '',
                    });
                  } else {
                    next.add({
                      'value': option.value,
                      'label': option.label,
                    });
                  }
                } else {
                  next.removeWhere((x) => x['value'] == option.value);
                }
                widget.onAnswerChanged(next);
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
              visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
            ),
            if (option.requiresFreeText && isChecked)
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 8, top: 4),
                child: TextField(
                  controller: _getFreeTextController(ctrlKey),
                  decoration: InputDecoration(
                    labelText: 'Please specify',
                    labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppColors.borderSubtle),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppColors.primaryAccent, width: 1.6),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 14),
                  onChanged: (text) {
                    final next = List<Map<String, dynamic>>.from(selected);
                    final idx = next.indexWhere((x) => x['value'] == option.value);
                    if (idx >= 0) {
                      next[idx] = {
                        ...next[idx],
                        'requiresFreeText': true,
                        'freeText': text,
                      };
                      widget.onAnswerChanged(next);
                    }
                  },
                ),
              ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDropdown() {
    if (_options.isEmpty) {
      return AppText.styledBodyMedium(
        context,
        'No options available',
        color: AppColors.textMuted,
      );
    }

    final selectedValue = widget.currentAnswer is Map
        ? widget.currentAnswer['value']
        : widget.currentAnswer;

    final selectedOption = _options.firstWhere(
      (opt) => opt.value == selectedValue,
      orElse: () => _options.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.borderSubtle),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: AppColors.primaryAccent, width: 1.6),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            hintText: 'Choose an option',
            hintStyle: TextStyle(color: AppColors.textMuted),
            isDense: true,
          ),
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primary,
            fontFamily: 'Poppins',
          ),
          icon: Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
          items: _options.map((option) {
            return DropdownMenuItem(
              value: option.value,
              child: AppText.styledBodyMedium(context, option.label),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;
            final option = _options.firstWhere((opt) => opt.value == value);
            if (option.requiresFreeText) {
              final ctrlKey = '${widget.question.questionId}__${option.value}';
              _getFreeTextController(ctrlKey);
              widget.onAnswerChanged({
                'value': option.value,
                'label': option.label,
                'requiresFreeText': true,
                'freeText': _freeTextControllers[ctrlKey]?.text ?? '',
              });
            } else {
              widget.onAnswerChanged(option.value);
            }
          },
        ),
        if (selectedOption.requiresFreeText)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: _getFreeTextController(
                '${widget.question.questionId}__${selectedOption.value}',
              ),
              decoration: InputDecoration(
                labelText: 'Please specify',
                labelStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.borderSubtle),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.primaryAccent, width: 1.6),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (text) {
                widget.onAnswerChanged({
                  'value': selectedOption.value,
                  'label': selectedOption.label,
                  'requiresFreeText': true,
                  'freeText': text,
                });
              },
            ),
          ),
      ],
    );
  }
}
