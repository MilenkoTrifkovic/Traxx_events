import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:traxx_wepapp/services/guest_firestore_services.dart';

import 'demographic_constants.dart';

// ✅ Your DemographicQuestionCard is already correctly updated to opt.id.
// Keeping it here as-is (same as your latest version) so you can copy/paste
// the full file in one shot.

class DemographicQuestionCard extends StatelessWidget {
  final DemographicQuestion question;
  final bool isActive;
  final dynamic answer;
  final TextEditingController? textController;
  final Map<String, TextEditingController> freeTextCtrls;
  final VoidCallback onTap;
  final ValueChanged<dynamic> onAnswerChanged;
  final TextEditingController Function(String key) getFreeTextController;

  /// Read-only mode - disables all interactions
  final bool readOnly;

  const DemographicQuestionCard({
    super.key,
    required this.question,
    required this.isActive,
    required this.answer,
    required this.textController,
    required this.freeTextCtrls,
    required this.onTap,
    required this.onAnswerChanged,
    required this.getFreeTextController,
    this.readOnly = false,
  });

  String? _selectedOptionId() {
    if (answer is String) {
      final s = (answer as String).trim();
      if (s.isEmpty) return null;
      if (question.options.any((o) => o.id == s)) return s;
      final byValue = question.options.where((o) => o.value == s);
      if (byValue.isNotEmpty) return byValue.first.id;
      return null;
    }

    if (answer is Map) {
      final m = answer as Map;
      final optId = (m['optionId'] ?? '').toString().trim();
      if (optId.isNotEmpty && question.options.any((o) => o.id == optId)) {
        return optId;
      }
      final legacyVal = (m['value'] ?? '').toString().trim();
      if (legacyVal.isNotEmpty) {
        final byValue = question.options.where((o) => o.value == legacyVal);
        if (byValue.isNotEmpty) return byValue.first.id;
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _selectedCheckboxItems() {
    if (answer is! List) return <Map<String, dynamic>>[];

    final out = <Map<String, dynamic>>[];
    for (final item in (answer as List)) {
      if (item is Map) {
        out.add(Map<String, dynamic>.from(item as Map));
      } else if (item is String) {
        out.add({'optionId': item});
      }
    }
    return out;
  }

  bool _isChecked(DemographicOption opt, List<Map<String, dynamic>> selected) {
    return selected.any((x) {
      final optId = (x['optionId'] ?? '').toString();
      if (optId.isNotEmpty) return optId == opt.id;

      final legacyVal = (x['value'] ?? '').toString();
      return legacyVal.isNotEmpty && legacyVal == opt.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final titleText =
        question.isRequired ? '${question.text} *' : question.text;

    return InkWell(
      onTap: readOnly ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: readOnly ? kBorder : (isActive ? kAccent : kBorder),
            width: readOnly ? 1 : (isActive ? 2 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withOpacity(isActive && !readOnly ? 0.08 : 0.04),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Icon(
                Icons.drag_indicator_rounded,
                size: 20,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              titleText,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(BuildContext context) {
    final effectiveEnabled = !readOnly && isActive;

    switch (question.type) {
      case 'short_answer':
      case 'paragraph':
        return TextField(
          controller: textController,
          enabled: effectiveEnabled,
          readOnly: readOnly,
          maxLines: question.type == 'paragraph' ? 4 : 1,
          onChanged: readOnly ? null : (v) => onAnswerChanged(v),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: readOnly ? kTextBody : kTextDark,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
            hintText: readOnly ? 'Text answer' : null,
            hintStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kAccent, width: 2),
            ),
          ),
        );

      case 'dropdown':
        final selectedId = _selectedOptionId();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IgnorePointer(
              ignoring: readOnly,
              child: DropdownButtonFormField<String>(
                value: selectedId,
                isExpanded: true,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: readOnly ? Colors.grey.shade300 : kBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: kAccent, width: 2),
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
                  for (final opt in question.options)
                    DropdownMenuItem(
                      value: opt.id,
                      child: Text(
                        opt.label,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: readOnly ? kTextBody : kTextDark,
                        ),
                      ),
                    ),
                ],
                onChanged: readOnly
                    ? null
                    : (optId) {
                        if (!isActive) onTap();
                        if (optId == null) {
                          onAnswerChanged(null);
                          return;
                        }
                        final opt =
                            question.options.firstWhere((o) => o.id == optId);
                        if (opt.requiresFreeText) {
                          final ctrlKey = '${question.id}__${opt.id}';
                          getFreeTextController(ctrlKey);
                          onAnswerChanged({
                            'optionId': opt.id,
                            'value': opt.value,
                            'label': opt.label,
                            'requiresFreeText': true,
                            'freeText': freeTextCtrls[ctrlKey]?.text ?? '',
                          });
                        } else {
                          onAnswerChanged(opt.id);
                        }
                      },
              ),
            ),
            const SizedBox(height: 8),
            _maybeFreeTextForSingleChoice(),
          ],
        );

      case 'checkboxes':
        final selected = _selectedCheckboxItems();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final opt in question.options) _checkboxRow(opt, selected),
          ],
        );

      case 'multiple_choice':
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final opt in question.options) _radioRow(opt),
            _maybeFreeTextForSingleChoice(),
          ],
        );
    }
  }

  Widget _radioRow(DemographicOption opt) {
    final selectedId = _selectedOptionId();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Radio<String>(
              value: opt.id,
              groupValue: selectedId,
              onChanged: readOnly
                  ? null
                  : (v) {
                      if (v == null) return;
                      if (!isActive) onTap();
                      if (opt.requiresFreeText) {
                        final ctrlKey = '${question.id}__${opt.id}';
                        getFreeTextController(ctrlKey);
                        onAnswerChanged({
                          'optionId': opt.id,
                          'value': opt.value,
                          'label': opt.label,
                          'requiresFreeText': true,
                          'freeText': freeTextCtrls[ctrlKey]?.text ?? '',
                        });
                      } else {
                        onAnswerChanged(opt.id);
                      }
                    },
              activeColor: kAccent,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          Expanded(
            child: Text(
              opt.label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: readOnly ? kTextBody : kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkboxRow(
      DemographicOption opt, List<Map<String, dynamic>> selected) {
    final isChecked = _isChecked(opt, selected);
    final ctrlKey = '${question.id}__${opt.id}';

    if (opt.requiresFreeText && !readOnly) {
      getFreeTextController(ctrlKey);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Checkbox(
                  value: isChecked,
                  onChanged: readOnly
                      ? null
                      : (v) {
                          if (!isActive) onTap();
                          final next =
                              List<Map<String, dynamic>>.from(selected);
                          if (v == true) {
                            if (opt.requiresFreeText) {
                              next.add({
                                'optionId': opt.id,
                                'value': opt.value,
                                'label': opt.label,
                                'requiresFreeText': true,
                                'freeText': freeTextCtrls[ctrlKey]?.text ?? '',
                              });
                            } else {
                              next.add({
                                'optionId': opt.id,
                                'value': opt.value,
                                'label': opt.label,
                              });
                            }
                          } else {
                            next.removeWhere((x) {
                              final oid = (x['optionId'] ?? '').toString();
                              if (oid.isNotEmpty) return oid == opt.id;
                              final legacyVal = (x['value'] ?? '').toString();
                              return legacyVal.isNotEmpty &&
                                  legacyVal == opt.value;
                            });
                          }
                          onAnswerChanged(next);
                        },
                  activeColor: kAccent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Expanded(
                child: Text(
                  opt.label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: readOnly ? kTextBody : kTextDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (opt.requiresFreeText && isChecked && !readOnly)
          Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 10),
            child: TextField(
              controller: freeTextCtrls[ctrlKey],
              enabled: isActive && !readOnly,
              decoration: InputDecoration(
                labelText: 'Please specify',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kAccent, width: 2),
                ),
              ),
              onChanged: readOnly
                  ? null
                  : (txt) {
                      final next = List<Map<String, dynamic>>.from(selected);
                      final idx =
                          next.indexWhere((x) => x['optionId'] == opt.id);
                      if (idx >= 0) {
                        next[idx] = {
                          ...next[idx],
                          'optionId': opt.id,
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
    if (readOnly) return const SizedBox.shrink();
    if (answer is! Map) return const SizedBox.shrink();

    final a = answer as Map;
    if (a['requiresFreeText'] != true) return const SizedBox.shrink();

    final optId = (a['optionId'] ?? '').toString().trim();
    if (optId.isEmpty) return const SizedBox.shrink();

    final ctrlKey = '${question.id}__${optId}';
    final ctrl = getFreeTextController(ctrlKey);

    if (ctrl.text.isEmpty && a['freeText'] != null) {
      ctrl.text = a['freeText'].toString();
    }

    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 8),
      child: TextField(
        controller: ctrl,
        enabled: isActive,
        decoration: InputDecoration(
          labelText: 'Please specify',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: kAccent, width: 2),
          ),
        ),
        onChanged: (txt) => onAnswerChanged({...a, 'freeText': txt}),
      ),
    );
  }
}
