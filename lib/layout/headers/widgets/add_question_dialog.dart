import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traxx_wepapp/controller/admin_controllers/host_questions_controller.dart';
import 'package:traxx_wepapp/models/host_questions_option.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

const Color _gfPurple = Color(0xFF673AB7);
const Color _gfTextColor = Color(0xFF202124);

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
  final bool _lastOptionFreeText = false;
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
                                initialValue: _questionType,
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
                                activeThumbColor: _gfPurple,
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
