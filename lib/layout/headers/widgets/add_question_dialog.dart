import 'package:flutter/material.dart';
import 'package:traxx_wepapp/controller/admin_controllers/host_questions_controller.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

class AddQuestionDialog extends StatefulWidget {
  const AddQuestionDialog({super.key});

  @override
  State<AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<AddQuestionDialog> {
  final _formKey = GlobalKey<FormState>();

  final _questionTextCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController(text: 'profile');
  String _questionType = 'single_select';
  bool _isRequired = true;
  final _optionsCtrl = TextEditingController(
    text: 'Option 1\nOption 2\nOption 3',
  );
  bool _lastOptionHasFreeText = false;

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
    _categoryCtrl.dispose();
    _optionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companyId = ''; // TODO: plug your real company id
    final eventId = ''; // optional

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.quiz_rounded, color: AppColors.primaryAccent),
                    const SizedBox(width: 8),
                    AppText.styledHeadingMedium(
                      context,
                      'Add Demographic Question',
                      color: Colors.black,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed:
                          _isSubmitting ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Question text
                TextFormField(
                  controller: _questionTextCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Question text',
                    hintText: 'e.g. Do you have any dietary restrictions?',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter a question'
                      : null,
                ),
                const SizedBox(height: 12),

                // Category + type row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _categoryCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          hintText: 'e.g. dietary, profile, accessibility',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _questionType,
                        items: const [
                          DropdownMenuItem(
                            value: 'single_select',
                            child: Text('Single select (radio)'),
                          ),
                          DropdownMenuItem(
                            value: 'multi_select',
                            child: Text('Multi select (checkboxes)'),
                          ),
                          DropdownMenuItem(
                            value: 'text',
                            child: Text('Free text answer'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _questionType = v);
                        },
                        decoration: const InputDecoration(
                          labelText: 'Question type',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Switch(
                      value: _isRequired,
                      onChanged: (v) => setState(() => _isRequired = v),
                    ),
                    const SizedBox(width: 4),
                    const Text('Required'),
                  ],
                ),
                const SizedBox(height: 8),

                if (_questionType != 'text') ...[
                  AppText.styledBodySmall(
                    context,
                    'Options (one per line)',
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _optionsCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Vegetarian\nVegan\nHalal\nAllergies (please specify)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _lastOptionHasFreeText,
                        onChanged: (v) =>
                            setState(() => _lastOptionHasFreeText = v ?? false),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                          'Last option has free-text (e.g. "Other, please specify")'),
                    ],
                  ),
                ],

                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            try {
                              setState(() => _isSubmitting = true);

                              final List<NewOptionInput> optionInputs = [];
                              if (_questionType != 'text') {
                                final lines = _optionsCtrl.text
                                    .split('\n')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();

                                for (int i = 0; i < lines.length; i++) {
                                  final label = lines[i];
                                  optionInputs.add(
                                    NewOptionInput(
                                      label: label,
                                      value: label
                                          .toLowerCase()
                                          .replaceAll(' ', '_'),
                                      requiresFreeText:
                                          _lastOptionHasFreeText &&
                                              i == lines.length - 1,
                                    ),
                                  );
                                }
                              }

                              await _controller.createQuestionWithOptions(
                                questionText: _questionTextCtrl.text.trim(),
                                questionCategory: _categoryCtrl.text.trim(),
                                questionType: _questionType,
                                isRequired: _isRequired,
                                companyId: companyId,
                                eventId: eventId,
                                options: optionInputs,
                              );

                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to add question: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isSubmitting = false);
                              }
                            }
                          },
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_isSubmitting ? 'Saving...' : 'Save Question'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
