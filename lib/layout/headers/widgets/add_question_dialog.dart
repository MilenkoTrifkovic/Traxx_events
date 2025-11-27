import 'package:flutter/material.dart';
import 'package:traxx_wepapp/controller/admin_controllers/host_questions_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

const Color _gfPurple = Color(0xFF673AB7);
const Color _gfTextColor = Color(0xFF202124);

class AddQuestionDialog extends StatefulWidget {
  final String questionSetId;

  const AddQuestionDialog({
    super.key,
    required this.questionSetId,
  });

  @override
  State<AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<AddQuestionDialog> {
  final _formKey = GlobalKey<FormState>();

  final _questionTextCtrl = TextEditingController();
  String _questionType = 'multiple_choice'; // 'short_answer', 'paragraph', etc.
  bool _isRequired = false;
  bool _lastOptionFreeText = false;
  bool _showTypeList = false;
  String? _questionError;

  final List<_OptionItem> _options = [
    _OptionItem('Option 1'),
    _OptionItem('Option 2'),
  ];

  bool _isSubmitting = false;
  late final HostQuestionsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HostQuestionsController();
  }

  @override
  void dispose() {
    _questionTextCtrl.dispose();
    for (final o in _options) {
      o.controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add(_OptionItem('Option ${_options.length + 1}'));
    });
  }

  void _removeOption(int index) {
    setState(() {
      if (_options.length > 1) {
        _options.removeAt(index);
      } else {
        _options[index].controller.clear();
      }
    });
  }

  Future<void> _submit() async {
    if (_questionTextCtrl.text.trim().isEmpty) {
      setState(() {
        _questionError = 'Please enter a question';
      });
      return;
    } else {
      setState(() {
        _questionError = null;
      });
    }

    final optionInputs = <NewOptionInput>[];
    final trimmed = _options
        .map((o) => o.controller.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    for (int i = 0; i < trimmed.length; i++) {
      final label = trimmed[i];
      optionInputs.add(
        NewOptionInput(
          label: label,
          value: label.toLowerCase().replaceAll(' ', '_'),
          requiresFreeText: _lastOptionFreeText && i == trimmed.length - 1,
        ),
      );
    }

    setState(() => _isSubmitting = true);

    try {
      const companyId = '';
      const eventId = '';

      await _controller.createQuestionWithOptions(
        questionSetId: widget.questionSetId,
        questionText: _questionTextCtrl.text.trim(),
        questionType: _questionType,
        isRequired: _isRequired,
        options: optionInputs,
      );

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add question: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _showAddFieldsSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Add fields',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _gfTextColor,
                    ),
                  ),
                ),
              ),
              ..._fieldTypes.map((t) {
                return InkWell(
                  onTap: () => Navigator.of(context).pop(t.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        Icon(t.icon, size: 18, color: _gfPurple),
                        const SizedBox(width: 10),
                        Text(
                          t.label,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _gfTextColor,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Add',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _gfPurple,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _questionType = selected;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🔹 TOP PURPLE HEADER
                Container(
                  width: double.infinity,
                  color: _gfPurple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.tune_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      const Text(
                        'Add question',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                ),

                // BODY
                Flexible(
                    child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADING: Question text
                        const Text(
                          'Question text',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _gfTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Builder(
                          builder: (context) {
                            final hasError = _questionError != null;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _questionTextCtrl,
                                  decoration: InputDecoration(
                                    hintText:
                                        'e.g. Do you have any dietary restrictions?',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: hasError
                                            ? Colors.red
                                            : const Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color: hasError
                                            ? Colors.red
                                            : const Color(0xFFE0E0E0),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(
                                        color:
                                            hasError ? Colors.red : _gfPurple,
                                        width: 1.5,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: _gfTextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (hasError)
                                  const Text(
                                    'Please enter a question',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.red,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // HEADING: Question type
                        const Text(
                          'Question type',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _gfTextColor,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Question type + Required toggle
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _questionType,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: Color(0xFFE0E0E0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                        color: _gfPurple, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                ),
                                selectedItemBuilder: (context) {
                                  return _fieldTypes.map((t) {
                                    return Row(
                                      children: [
                                        Icon(t.icon,
                                            size: 18, color: _gfPurple),
                                        const SizedBox(width: 8),
                                        Text(
                                          t.label,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: _gfTextColor,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList();
                                },
                                items: _fieldTypes.map((t) {
                                  return DropdownMenuItem<String>(
                                    value: t.value,
                                    child: Row(
                                      children: [
                                        Icon(t.icon,
                                            size: 18, color: _gfPurple),
                                        const SizedBox(width: 8),
                                        Text(
                                          t.label,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: _gfTextColor,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Text(
                                          'Add',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _gfPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _questionType = v);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Required',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Transform.scale(
                              scale: 0.8, // smaller toggle
                              alignment: Alignment.centerLeft,
                              child: Switch(
                                value: _isRequired,
                                onChanged: (v) =>
                                    setState(() => _isRequired = v),
                                activeColor: _gfPurple,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        /* // ADD FIELDS BAR (visual / picker)
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              _showTypeList = !_showTypeList;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _gfPurple, width: 1),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.add_circle_outline,
                                    size: 18, color: _gfPurple),
                                SizedBox(width: 8),
                                Text(
                                  'Add fields',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _gfPurple,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.keyboard_arrow_down_rounded,
                                    size: 20, color: _gfPurple),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20), */

                        const SizedBox(height: 8),

                        if (_showTypeList)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFE2E3EF)),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  offset: const Offset(0, 6),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: _fieldTypes.map((t) {
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _questionType = t.value;
                                      _showTypeList = false;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    child: Row(
                                      children: [
                                        Icon(t.icon,
                                            size: 18, color: _gfPurple),
                                        const SizedBox(width: 10),
                                        Text(
                                          t.label,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: _gfTextColor,
                                          ),
                                        ),
                                        const Spacer(),
                                        const Text(
                                          'Add',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: _gfPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        // HEADING: Options (only for choice-type questions)
                        if (_questionType == 'multiple_choice' ||
                            _questionType == 'checkboxes' ||
                            _questionType == 'dropdown') ...[
                          const Text(
                            'Options',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _gfTextColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._buildOptionFields(),
                          const SizedBox(height: 4),
                          TextButton.icon(
                            onPressed: _addOption,
                            icon: const Icon(Icons.add,
                                size: 18, color: _gfPurple),
                            label: const Text(
                              'Add option',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _gfPurple,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                )),

                // FOOTER BUTTONS (like Cancel / Save changes)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF8F8FB),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF5F6368),
                          textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gfPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                ),
                              )
                            : const Text('Save changes'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildOptionFields() {
    final widgets = <Widget>[];
    for (int i = 0; i < _options.length; i++) {
      final item = _options[i];
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: item.controller,
                  decoration: const InputDecoration(
                    isDense: true,
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: _gfTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isSubmitting ? null : () => _removeOption(i),
                icon: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Colors.black87, // or Colors.black
                ),
                tooltip: 'Remove option',
              ),
            ],
          ),
        ),
      );
    }
    return widgets;
  }
}

class _OptionItem {
  final TextEditingController controller;
  _OptionItem(String label) : controller = TextEditingController(text: label);
}

class _FieldType {
  final String value;
  final String label;
  final IconData icon;

  const _FieldType(this.value, this.label, this.icon);
}

// The five field types shown in the "Add fields" list
const List<_FieldType> _fieldTypes = [
  _FieldType('short_answer', 'Short answer', Icons.text_fields_rounded),
  _FieldType('paragraph', 'Paragraph', Icons.subject_rounded),
  _FieldType('multiple_choice', 'Multiple choice', Icons.radio_button_checked),
  _FieldType('checkboxes', 'Checkboxes', Icons.check_box_outlined),
  _FieldType('dropdown', 'Dropdown', Icons.arrow_drop_down_circle_outlined),
];
