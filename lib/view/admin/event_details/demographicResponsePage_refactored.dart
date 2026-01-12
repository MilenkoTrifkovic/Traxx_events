import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:traxx_wepapp/controller/global_controllers/demographic_response_controller.dart';

import 'demographic_widgets/demographic_constants.dart';
import 'demographic_widgets/demographic_info_card.dart';
import 'demographic_widgets/demographic_question_card.dart';

class DemographicResponsePage extends StatefulWidget {
  /// For interactive mode (guest filling out)
  final String invitationId;
  final String token;
  final int? companionIndex;
  final String? companionName;
  final bool showInvitationInput;
  final bool embedded;

  /// Read-only mode - just display questions without interaction
  final bool readOnly;

  /// Question set ID - used when readOnly = true (no invitation needed)
  final String? questionSetId;

  const DemographicResponsePage({
    super.key,
    this.invitationId = '',
    this.token = '',
    this.companionIndex,
    this.companionName,
    this.showInvitationInput = false,
    this.embedded = false,
    this.readOnly = false,
    this.questionSetId,
  });

  /// Named constructor for read-only preview mode
  const DemographicResponsePage.preview({
    super.key,
    required this.questionSetId,
  })  : invitationId = '',
        token = '',
        companionIndex = null,
        companionName = null,
        showInvitationInput = false,
        embedded = true,
        readOnly = true;

  @override
  State<DemographicResponsePage> createState() =>
      _DemographicResponsePageState();
}

class _DemographicResponsePageState extends State<DemographicResponsePage> {
  late final DemographicResponseController _controller;
  late final TextEditingController _invitationIdCtrl;
  final ScrollController _listCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _invitationIdCtrl = TextEditingController(text: widget.invitationId);

    // Create controller with unique tag
    final tag = widget.readOnly
        ? 'preview_${widget.questionSetId}'
        : '${widget.invitationId}_${widget.companionIndex ?? "main"}';

    _controller = Get.put(
      DemographicResponseController(
        invitationId: widget.invitationId,
        token: widget.token,
        companionIndex: widget.companionIndex,
        companionName: widget.companionName,
        showInvitationInput: widget.showInvitationInput,
        readOnly: widget.readOnly,
        questionSetId: widget.questionSetId,
      ),
      tag: tag,
    );
  }

  @override
  void didUpdateWidget(covariant DemographicResponsePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Skip updates in read-only mode
    if (widget.readOnly) return;

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
    final tag = widget.readOnly
        ? 'preview_${widget.questionSetId}'
        : '${widget.invitationId}_${widget.companionIndex ?? "main"}';
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
                                // Progress indicator - show when there are companions (not in read-only)
                                if (!widget.readOnly &&
                                    _controller.hasCompanions) ...[
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
                                // Invitation loader - not in read-only mode
                                if (!widget.readOnly &&
                                    widget.showInvitationInput) ...[
                                  _buildInvitationLoaderCard(),
                                  const SizedBox(height: 16),
                                ],
                                _buildHeaderWithAction(),
                                const SizedBox(height: 14),
                                // Helper text - not in read-only mode
                                if (!widget.readOnly &&
                                    !_controller.isLoading.value &&
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
              '${_controller.completedCount + (_controller.isCurrentPersonDone ? 0 : 1)} / ${_controller.totalPeople}',
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
        // Hide action button in read-only mode
        if (!widget.readOnly) ...[
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(
                      _controller.isCurrentPersonDone ? 'Continue' : 'Next'),
                ),
              )),
        ],
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

      // Only show "waiting for invitation" message in interactive mode
      if (!widget.readOnly &&
          _controller.invitation.value == null &&
          _controller.activeInvitationId.isEmpty) {
        return const DemographicInfoCard(
          icon: Icons.info_outline_rounded,
          iconColor: kGfPurple,
          title: 'Waiting for invitation',
          message: 'Paste an invitationId above and click Load.',
        );
      }

      if (_controller.hasError) {
        return DemographicInfoCard(
          icon: Icons.error_outline_rounded,
          iconColor: Colors.red.shade600,
          title:
              _controller.errorTitle.value ?? 'Invalid or expired invitation',
          message: _controller.errorMessage.value ??
              'Please check your link and try again.',
        );
      }

      // Only show "already submitted" message in interactive mode
      if (!widget.readOnly && _controller.isCurrentPersonDone) {
        final name = _controller.currentCompanionIndex == null
            ? 'Your'
            : '${_controller.currentPersonName.value}\'s';
        return DemographicInfoCard(
          icon: Icons.check_circle_outline_rounded,
          iconColor: Colors.green,
          title: 'Already submitted',
          message:
              '$name responses were already submitted. Click Continue to proceed.',
        );
      }

      if (_controller.questions.isEmpty) {
        return const DemographicInfoCard(
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
            final parent = q.parentQuestionId ?? '';
            final trigger = q.triggerOptionId ?? '';

            // ✅ Add this line HERE
            final isSub = parent.trim().isNotEmpty;

            return Obx(() {
              final isActive = q.id == _controller.activeQuestionId.value;
              final answer = _controller.answers[q.id];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  // ✅ indent sub-questions a bit
                  padding: EdgeInsets.only(left: isSub ? 24 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ✅ badge so you can SEE which ones are real sub-questions
                      // if (isSub)
                      //   Padding(
                      //     padding: const EdgeInsets.only(bottom: 6),
                      //     child: Align(
                      //       alignment: Alignment.centerLeft,
                      //       child: Container(
                      //         padding: const EdgeInsets.symmetric(
                      //             horizontal: 10, vertical: 5),
                      //         decoration: BoxDecoration(
                      //           color: Colors.black.withOpacity(0.06),
                      //           borderRadius: BorderRadius.circular(999),
                      //         ),
                      //         child: Text(
                      //           'Follow-up',
                      //           style: GoogleFonts.poppins(
                      //             fontSize: 12,
                      //             fontWeight: FontWeight.w600,
                      //             color: Colors.black87,
                      //           ),
                      //         ),
                      //       ),
                      //     ),
                      //   ),

                      DemographicQuestionCard(
                        question: q,
                        isActive: isActive,
                        answer: answer,
                        textController: widget.readOnly
                            ? null
                            : _controller.getTextController(q.id),
                        freeTextCtrls: _controller.freeTextControllers,
                        onTap: () => _controller.setActiveQuestion(q.id),
                        onAnswerChanged: (value) =>
                            _controller.updateAnswer(q.id, value),
                        getFreeTextController:
                            _controller.getFreeTextController,
                        readOnly: widget.readOnly,
                      ),
                    ],
                  ),
                ),
              );
            });
          },
        ),
      );
    });
  }
}
