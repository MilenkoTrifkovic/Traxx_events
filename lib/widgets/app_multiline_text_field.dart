import 'package:flutter/material.dart';

/// Simple multiline text field with scroll support
///
/// Minimal implementation - just a TextField with:
/// - Multiline support
/// - Auto-scroll when content exceeds maxHeight
/// - Basic styling support
class AppMultilineTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final TextStyle style;
  final double minHeight;
  final double maxHeight;
  final ValueChanged<String>? onChanged;

  const AppMultilineTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.style,
    this.minHeight = 44,
    this.maxHeight = 160,
    this.onChanged,
  });

  @override
  State<AppMultilineTextField> createState() => _AppMultilineTextFieldState();
}

class _AppMultilineTextFieldState extends State<AppMultilineTextField> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: widget.minHeight,
        maxHeight: widget.maxHeight,
      ),
      child: Scrollbar(
        controller: _scrollController,
        child: EditableText(
          controller: widget.controller,
          focusNode: widget.focusNode,
          style: widget.style,
          cursorColor: Colors.blue,
          backgroundCursorColor: Colors.black,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          onChanged: widget.onChanged,
          scrollController: _scrollController,
        ),
      ),
    );
  }
}
