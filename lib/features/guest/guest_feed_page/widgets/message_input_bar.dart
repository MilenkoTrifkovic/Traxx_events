import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
  final Function(int index)? onRemoveFile;
  final bool isEnabled;
  final bool isSending;
  final String? hintText;
  final List<String>? selectedFileNames;
  final List<String>? selectedFileTypes;
  final List<PlatformFile>? selectedFiles; // Add this to access file data

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
    this.selectedFileNames,
    this.selectedFileTypes,
    this.selectedFiles,
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
    final hasFiles = widget.selectedFileNames != null && widget.selectedFileNames!.isNotEmpty;
    // Allow sending if there's text OR files attached
    if ((text.isNotEmpty || hasFiles) && widget.isEnabled) {
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
            // Selected files list (shown above input)
            if (widget.selectedFileNames != null &&
                widget.selectedFileNames!.isNotEmpty) ...[
              _buildSelectedFilesGrid(context, isPhone),
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
                        onPressed: (_hasText || (widget.selectedFileNames != null && widget.selectedFileNames!.isNotEmpty)) && widget.isEnabled
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

  /// Builds a grid of selected file cards
  Widget _buildSelectedFilesGrid(BuildContext context, bool isPhone) {
    if (widget.selectedFileNames == null || widget.selectedFileNames!.isEmpty) {
      return SizedBox.shrink();
    }

    return Wrap(
      spacing: AppSpacing.sm(context),
      runSpacing: AppSpacing.sm(context),
      children: List.generate(
        widget.selectedFileNames!.length,
        (index) => _buildSelectedFileCard(
          context,
          isPhone,
          index,
        ),
      ),
    );
  }

  /// Builds a single selected file card
  Widget _buildSelectedFileCard(BuildContext context, bool isPhone, int index) {
    if (widget.selectedFileNames == null || 
        widget.selectedFileTypes == null ||
        index >= widget.selectedFileNames!.length ||
        index >= widget.selectedFileTypes!.length) {
      return SizedBox.shrink();
    }

    final fileName = widget.selectedFileNames![index];
    final fileType = widget.selectedFileTypes![index];
    final isPdf = fileType == 'pdf';
    final isImage = fileType == 'image';

    return InkWell(
      onTap: isImage && widget.selectedFiles != null && index < widget.selectedFiles!.length
          ? () => _showImagePreview(context, widget.selectedFiles![index])
          : null,
      borderRadius: BorderRadius.circular(isPhone ? 8 : 10),
      child: Container(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            // File icon or thumbnail
            Container(
              width: isPhone ? 36.0 : 40.0,
              height: isPhone ? 36.0 : 40.0,
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isPhone ? 6 : 8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isPhone ? 6 : 8),
                child: isPdf
                    ? Icon(
                        Icons.picture_as_pdf,
                        size: isPhone ? 20.0 : 24.0,
                        color: AppColors.primaryAccent,
                      )
                    : isImage && widget.selectedFiles != null && index < widget.selectedFiles!.length
                        ? _buildThumbnail(widget.selectedFiles![index])
                        : Icon(
                            Icons.image,
                            size: isPhone ? 20.0 : 24.0,
                            color: AppColors.primaryAccent,
                          ),
              ),
            ),
            AppSpacing.horizontalSm(context),
            // File name
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isPhone ? 150 : 200,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
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
                    isPdf ? 'PDF Document' : isImage ? 'Tap to preview' : 'Image',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: isPhone ? 12 : 13,
                      color: isImage ? AppColors.primaryAccent : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            AppSpacing.horizontalXxs(context),
            // Remove button
            if (widget.onRemoveFile != null)
              IconButton(
                onPressed: widget.isEnabled ? () => widget.onRemoveFile!(index) : null,
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
      ),
    );
  }

  /// Shows image preview dialog
  void _showImagePreview(BuildContext context, PlatformFile file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            // Image
            Center(
              child: InteractiveViewer(
                child: _buildImageWidget(file),
              ),
            ),
            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.close, color: AppColors.white, size: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the appropriate image widget based on platform
  Widget _buildImageWidget(PlatformFile file) {
    if (kIsWeb) {
      // For web, use bytes
      if (file.bytes != null) {
        return Image.memory(
          file.bytes!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        );
      }
    } else {
      // For mobile, use file path
      if (file.path != null) {
        return Image.file(
          File(file.path!),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        );
      }
    }
    
    return _buildErrorWidget();
  }

  /// Builds a thumbnail for the file card
  Widget _buildThumbnail(PlatformFile file) {
    if (kIsWeb) {
      // For web, use bytes
      if (file.bytes != null) {
        return Image.memory(
          file.bytes!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.image,
              size: 20.0,
              color: AppColors.primaryAccent,
            );
          },
        );
      }
    } else {
      // For mobile, use file path
      if (file.path != null) {
        return Image.file(
          File(file.path!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.image,
              size: 20.0,
              color: AppColors.primaryAccent,
            );
          },
        );
      }
    }
    
    return Icon(
      Icons.image,
      size: 20.0,
      color: AppColors.primaryAccent,
    );
  }

  /// Builds error widget for failed image loading
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.white,
            size: 48,
          ),
          SizedBox(height: 16),
          Text(
            'Failed to load image',
            style: TextStyle(color: AppColors.white),
          ),
        ],
      ),
    );
  }
}
