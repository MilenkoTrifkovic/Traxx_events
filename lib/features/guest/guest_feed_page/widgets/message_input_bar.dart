import 'package:flutter/material.dart';
import 'package:traxx_wepapp/features/guest/guest_feed_page/widgets/message_input_buttons.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/widgets/app_multiline_text_field.dart';

/// Widget for composing and sending messages
class MessageInputBar extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final Function(String text) onSendMessage;
  final Function()? onAttachFile;
  final Function()? onRemoveFile;
  final bool isEnabled;
  final bool isSending;
  final String? hintText;
  final String? selectedFileName;
  final String? selectedFileType;

  const MessageInputBar({
    super.key,
    this.controller,
    this.focusNode,
    required this.onSendMessage,
    this.onAttachFile,
    this.onRemoveFile,
    this.isEnabled = true,
    this.isSending = false,
    this.hintText,
    this.selectedFileName,
    this.selectedFileType,
  });

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  late TextEditingController _messageController;
  late FocusNode _focusNode;
  bool _hasText = false;
  bool _controllerOwned = false;
  bool _focusNodeOwned = false;

  @override
  void initState() {
    super.initState();

    // Use provided controller or create own
    if (widget.controller != null) {
      _messageController = widget.controller!;
      _controllerOwned = false;
    } else {
      _messageController = TextEditingController();
      _controllerOwned = true;
    }

    // Use provided focusNode or create own
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
      _focusNodeOwned = false;
    } else {
      _focusNode = FocusNode();
      _focusNodeOwned = true;
    }

    _messageController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);

    // Only dispose if we own them
    if (_controllerOwned) {
      _messageController.dispose();
    }
    if (_focusNodeOwned) {
      _focusNode.dispose();
    }

    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _onFocusChanged() {
    setState(() {
      // Rebuild to update border color
    });
  }

  void _handleSendMessage() {
    final text = _messageController.text.trim();
    final hasFile = widget.selectedFileName != null && widget.selectedFileName!.isNotEmpty;
    // Allow sending if there's text OR a file attached
    if ((text.isNotEmpty || hasFile) && widget.isEnabled) {
      widget.onSendMessage(text);
      _messageController.clear();
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);

    return Container(
      padding: EdgeInsets.all(AppSpacing.md(context)),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          top: BorderSide(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected file card (shown above input)
            if (widget.selectedFileName != null &&
                widget.selectedFileName!.isNotEmpty) ...[
              _buildSelectedFileCard(context, isPhone),
              AppSpacing.verticalSm(context),
            ],
            // Input row
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Input field container with attach button
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(isPhone ? 12 : 16),
                      border: Border.all(
                        color: _focusNode.hasFocus
                            ? AppColors.primaryAccent
                            : AppColors.borderInput,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Attach file button (optional)
                          if (widget.onAttachFile != null) ...[
                            AttachButton(
                              onPressed: widget.isEnabled
                                  ? widget.onAttachFile
                                  : null,
                              isPhone: isPhone,
                            ),
                            AppSpacing.horizontalSm(context),
                          ],
                          // Text input field
                          Expanded(
                            child: AppMultilineTextField(
                              controller: _messageController,
                              focusNode: _focusNode,
                              minHeight: isPhone ? 40.0 : 44.0,
                              maxHeight: isPhone ? 120.0 : 150.0,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: isPhone ? 14 : 16,
                                color: AppColors.primary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AppSpacing.horizontalSm(context),
                // Send button (outside the input field) or loading indicator
                widget.isSending
                    ? Container(
                        width: isPhone ? 40.0 : 44.0,
                        height: isPhone ? 40.0 : 44.0,
                        decoration: BoxDecoration(
                          color: AppColors.primaryAccent,
                          borderRadius:
                              BorderRadius.circular(isPhone ? 8 : 10),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: isPhone ? 20.0 : 24.0,
                            height: isPhone ? 20.0 : 24.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      )
                    : SendButton(
                        onPressed: (_hasText || (widget.selectedFileName != null && widget.selectedFileName!.isNotEmpty)) && widget.isEnabled
                            ? _handleSendMessage
                            : null,
                        isPhone: isPhone,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the selected file card
  Widget _buildSelectedFileCard(BuildContext context, bool isPhone) {
    final isPdf = widget.selectedFileType == 'pdf';

    return Container(
      padding: EdgeInsets.all(AppSpacing.sm(context)),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(isPhone ? 8 : 10),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: isPhone ? 36.0 : 40.0,
            height: isPhone ? 36.0 : 40.0,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isPhone ? 6 : 8),
            ),
            child: Icon(
              isPdf ? Icons.picture_as_pdf : Icons.image,
              size: isPhone ? 20.0 : 24.0,
              color: AppColors.primaryAccent,
            ),
          ),
          AppSpacing.horizontalSm(context),
          // File name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedFileName!,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isPhone ? 14 : 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  isPdf ? 'PDF Document' : 'Image',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: isPhone ? 12 : 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Remove button
          if (widget.onRemoveFile != null)
            IconButton(
              onPressed: widget.isEnabled ? widget.onRemoveFile : null,
              icon: Icon(
                Icons.close,
                size: isPhone ? 18.0 : 20.0,
                color: AppColors.textMuted,
              ),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: isPhone ? 32.0 : 36.0,
                minHeight: isPhone ? 32.0 : 36.0,
              ),
            ),
        ],
      ),
    );
  }
}
