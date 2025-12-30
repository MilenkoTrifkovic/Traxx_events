import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:traxx_wepapp/services/guest_firestore_services.dart';

import 'demographic_constants.dart';

// ------------------------------------------------------------
// Question card widget
// ------------------------------------------------------------
class DemographicQuestionCard extends StatelessWidget {
  final DemographicQuestion question;
  final bool isActive;
  final dynamic answer;
  final TextEditingController? textController;
  final Map<String, TextEditingController> freeTextCtrls;
  final VoidCallback onTap;
  final ValueChanged<dynamic> onAnswerChanged;
  final TextEditingController Function(String key) getFreeTextController;

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
  });

  @override
  Widget build(BuildContext context) {
    final titleText = question.isRequired ? '${question.text} *' : question.text;

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
    switch (question.type) {
      case 'short_answer':
      case 'paragraph':
        return TextField(
          controller: textController,
          enabled: isActive,
          maxLines: question.type == 'paragraph' ? 4 : 1,
          onChanged: (v) => onAnswerChanged(v),
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: kTextDark,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: kAccent, width: 2),
            ),
          ),
        );

      case 'dropdown':
        final selected = (answer is Map)
            ? (answer['value'] as String?)
            : (answer as String?);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selected,
              isExpanded: true,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kBorder),
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
                    value: opt.value,
                    child: Text(
                      opt.label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextDark,
                      ),
                    ),
                  ),
              ],
              onChanged: (v) {
                // Auto-activate card when selecting
                if (!isActive) onTap();
                if (v == null) {
                  onAnswerChanged(null);
                  return;
                }
                final opt = question.options.firstWhere(
                  (o) => o.value == v,
                );
                if (opt.requiresFreeText) {
                  final ctrlKey = '${question.id}__${opt.value}';
                  getFreeTextController(ctrlKey);
                  onAnswerChanged({
                    'value': opt.value,
                    'label': opt.label,
                    'requiresFreeText': true,
                    'freeText': freeTextCtrls[ctrlKey]?.text ?? '',
                  });
                } else {
                  onAnswerChanged(opt.value);
                }
              },
            ),
            const SizedBox(height: 8),
            _maybeFreeTextForSingleChoice(),
          ],
        );

      case 'checkboxes':
        final selected = (answer as List?)?.cast<Map<String, dynamic>>() ??
            <Map<String, dynamic>>[];
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
    final selected =
        (answer is Map) ? (answer['value'] as String?) : answer as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Radio<String>(
              value: opt.value,
              groupValue: selected,
              onChanged: (v) {
                if (v == null) return;
                // Auto-activate card when selecting
                if (!isActive) onTap();
                if (opt.requiresFreeText) {
                  final ctrlKey = '${question.id}__${opt.value}';
                  getFreeTextController(ctrlKey);
                  onAnswerChanged({
                    'value': opt.value,
                    'label': opt.label,
                    'requiresFreeText': true,
                    'freeText': freeTextCtrls[ctrlKey]?.text ?? '',
                  });
                } else {
                  onAnswerChanged(opt.value);
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
                color: kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkboxRow(DemographicOption opt, List<Map<String, dynamic>> selected) {
    final isChecked = selected.any((x) => x['value'] == opt.value);
    final ctrlKey = '${question.id}__${opt.value}';
    if (opt.requiresFreeText) {
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
                  onChanged: (v) {
                    // Auto-activate card when selecting
                    if (!isActive) onTap();
                    final next = List<Map<String, dynamic>>.from(selected);
                    if (v == true) {
                      if (opt.requiresFreeText) {
                        next.add({
                          'value': opt.value,
                          'label': opt.label,
                          'requiresFreeText': true,
                          'freeText': freeTextCtrls[ctrlKey]?.text ?? '',
                        });
                      } else {
                        next.add({
                          'value': opt.value,
                          'label': opt.label,
                        });
                      }
                    } else {
                      next.removeWhere((x) => x['value'] == opt.value);
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
                    color: kTextDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (opt.requiresFreeText && isChecked)
          Padding(
            padding: const EdgeInsets.only(left: 32, bottom: 10),
            child: TextField(
              controller: freeTextCtrls[ctrlKey],
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
              onChanged: (txt) {
                final next = List<Map<String, dynamic>>.from(selected);
                final idx = next.indexWhere((x) => x['value'] == opt.value);
                if (idx >= 0) {
                  next[idx] = {
                    ...next[idx],
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
    if (answer is! Map) return const SizedBox.shrink();
    final a = answer as Map;
    if (a['requiresFreeText'] != true) return const SizedBox.shrink();

    final value = (a['value'] ?? '').toString();
    if (value.isEmpty) return const SizedBox.shrink();

    final ctrlKey = '${question.id}__$value';
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
