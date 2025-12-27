import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:traxx_wepapp/controller/global_controllers/demographic_response_controller.dart';
import 'package:traxx_wepapp/services/guest_firestore_services.dart';

// ------------------------------------------------------------
// Styling constants (matches your host UI look)
// ------------------------------------------------------------
const Color kAccent = Color(0xFF6C4BFF);
const Color kBorder = Color(0xFFE5E7EB);
const Color kTextDark = Color(0xFF111827);
const Color kTextBody = Color(0xFF374151);
const Color kGfPurple = Color(0xFF673AB7);
const Color gfBackground = Color(0xFFF4F0FB);

class DemographicResponsePage extends StatefulWidget {
  final String invitationId;
  final String token;
  final int? companionIndex;
  final String? companionName;
  final bool showInvitationInput;
  final bool embedded;

  const DemographicResponsePage({
    super.key,
    required this.invitationId,
    this.token = '',
    this.companionIndex,
    this.companionName,
    this.showInvitationInput = false,
    this.embedded = false,
  });

  @override
  State<DemographicResponsePage> createState() => _DemographicResponsePageState();
}

class _DemographicResponsePageState extends State<DemographicResponsePage> {
  late final DemographicResponseController _controller;
  late final TextEditingController _invitationIdCtrl;
  final ScrollController _listCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _invitationIdCtrl = TextEditingController(text: widget.invitationId);
    
    // Create controller with unique tag based on invitationId + companionIndex
    final tag = '${widget.invitationId}_${widget.companionIndex ?? "main"}';
    _controller = Get.put(
      DemographicResponseController(
        invitationId: widget.invitationId,
        token: widget.token,
        companionIndex: widget.companionIndex,
        companionName: widget.companionName,
        showInvitationInput: widget.showInvitationInput,
      ),
      tag: tag,
    );
  }

  @override
  void didUpdateWidget(covariant DemographicResponsePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if companion index changed
    if (widget.companionIndex != oldWidget.companionIndex ||
        widget.invitationId != oldWidget.invitationId) {
      debugPrint('didUpdateWidget: companionIndex or invitationId changed');
      _controller.updateCompanionIndex(widget.companionIndex);
    }
  }

  @override
  void dispose() {
    _invitationIdCtrl.dispose();
    _listCtrl.dispose();
    
    // Delete controller with tag
    final tag = '${widget.invitationId}_${widget.companionIndex ?? "main"}';
    Get.delete<DemographicResponseController>(tag: tag);
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final viewportH = MediaQuery.of(ctx).size.height;
        final boundedH = constraints.hasBoundedHeight;
        final maxH = boundedH ? constraints.maxHeight : viewportH;
        final scrollH = (maxH - 280).clamp(260.0, 800.0);

        return SizedBox(
          width: double.infinity,
          height: boundedH ? maxH : null,
          child: Stack(
            children: [
              const Positioned.fill(child: ColoredBox(color: gfBackground)),
              Align(
                alignment: Alignment.topCenter,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1040),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 24,
                        ),
                        child: Obx(() => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Progress indicator - show when there are companions
                            if (_controller.hasCompanions) ...[
                              _buildProgressBanner(),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              'Demographics',
                              style: GoogleFonts.poppins(
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 18),
                            if (widget.showInvitationInput) ...[
                              _buildInvitationLoaderCard(),
                              const SizedBox(height: 16),
                            ],
                            _buildHeaderWithAction(),
                            const SizedBox(height: 14),
                            if (!_controller.isLoading.value &&
                                _controller.invitation.value != null &&
                                !_controller.isCurrentPersonDone)
                              Center(
                                child: Text(
                                  'Click on a question to answer',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: scrollH,
                              child: _buildScrollableBody(),
                            ),
                            const SizedBox(height: 24),
                          ],
                        )),
                      ),
                    ),
                  ),
                ),
              ),
              // Submitting overlay
              Obx(() {
                if (!_controller.isSubmitting.value) {
                  return const SizedBox.shrink();
                }
                return Positioned.fill(
                  child: Container(
                    color: gfBackground.withOpacity(0.35),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: kGfPurple,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: kGfPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kGfPurple.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.people_outline, color: kGfPurple, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _controller.fillingForLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kGfPurple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Person ${_controller.currentPersonNumber} of ${_controller.totalPeople} • ${_controller.completedCount} completed',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: kTextBody,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kGfPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_controller.completedCount} / ${_controller.totalPeople}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationLoaderCard() {
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
        children: [
          Container(
            height: 6,
            decoration: const BoxDecoration(
              color: kGfPurple,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _invitationIdCtrl,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      labelText: 'Paste invitationId',
                      labelStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
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
                  ),
                ),
                const SizedBox(width: 12),
                Obx(() => SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: (_controller.isLoading.value || 
                        _controller.isSubmitting.value)
                        ? null
                        : () {
                            final id = _invitationIdCtrl.text.trim();
                            if (id.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.black87,
                                  content: Text(
                                    'Please paste invitationId',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                              return;
                            }
                            _controller.loadForInvitation(id);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGfPurple,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Load'),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithAction() {
    final title = _controller.questionSetTitle.isEmpty
        ? 'Untitled form'
        : _controller.questionSetTitle;
    final description = _controller.questionSetDescription;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Card(
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
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
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: kTextDark,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Obx(() => SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: (!_controller.isLoading.value &&
                !_controller.isSubmitting.value &&
                _controller.invitation.value != null &&
                (_controller.isCurrentPersonDone ||
                    _controller.questions.isNotEmpty))
                ? () => _controller.submitAndContinue(context)
                : null,
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
            child: Text(_controller.isCurrentPersonDone ? 'Continue' : 'Next'),
          ),
        )),
      ],
    );
  }

  Widget _buildScrollableBody() {
    return Obx(() {
      if (_controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 3, color: kGfPurple),
        );
      }

      if (_controller.invitation.value == null && 
          _controller.activeInvitationId.isEmpty) {
        return const _InfoCard(
          icon: Icons.info_outline_rounded,
          iconColor: kGfPurple,
          title: 'Waiting for invitation',
          message: 'Paste an invitationId above and click Load.',
        );
      }

      if (_controller.hasError) {
        return _InfoCard(
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red.shade600,
          title: _controller.errorTitle.value ?? 'Invalid or expired invitation',
          message: _controller.errorMessage.value ?? 'Please check your link and try again.',
        );
      }

      if (_controller.isCurrentPersonDone) {
        final name = _controller.currentCompanionIndex == null
            ? 'Your'
            : '${_controller.currentPersonName.value}\'s';
        return _InfoCard(
          icon: Icons.check_circle_outline_rounded,
          iconColor: Colors.green,
          title: 'Already submitted',
          message: '$name responses were already submitted. Click Continue to proceed.',
        );
      }

      if (_controller.questions.isEmpty) {
        return const _InfoCard(
          icon: Icons.help_outline_rounded,
          iconColor: kGfPurple,
          title: 'No questions in this set',
          message: 'There are no demographic questions to answer.',
        );
      }

      return Scrollbar(
        controller: _listCtrl,
        thumbVisibility: true,
        child: ListView.builder(
          controller: _listCtrl,
          padding: EdgeInsets.zero,
          itemCount: _controller.questions.length,
          itemBuilder: (_, idx) {
            final q = _controller.questions[idx];
            
            // Wrap each card in Obx to ensure it rebuilds when answer/activeQuestion changes
            return Obx(() {
              final isActive = q.id == _controller.activeQuestionId.value;
              final answer = _controller.answers[q.id];
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _QuestionCard(
                  question: q,
                  isActive: isActive,
                  answer: answer,
                  textController: _controller.getTextController(q.id),
                  freeTextCtrls: _controller.freeTextControllers,
                  onTap: () => _controller.setActiveQuestion(q.id),
                  onAnswerChanged: (value) => _controller.updateAnswer(q.id, value),
                  getFreeTextController: _controller.getFreeTextController,
                ),
              );
            });
          },
        ),
      );
    });
  }
}

// ------------------------------------------------------------
// Info card widget
// ------------------------------------------------------------
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: iconColor),
            const SizedBox(height: 14),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
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
    );
  }
}

// ------------------------------------------------------------
// Question card widget
// ------------------------------------------------------------
class _QuestionCard extends StatelessWidget {
  final DemographicQuestion question;
  final bool isActive;
  final dynamic answer;
  final TextEditingController? textController;
  final Map<String, TextEditingController> freeTextCtrls;
  final VoidCallback onTap;
  final ValueChanged<dynamic> onAnswerChanged;
  final TextEditingController Function(String key) getFreeTextController;

  const _QuestionCard({
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
