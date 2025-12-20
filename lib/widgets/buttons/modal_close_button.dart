import 'package:flutter/material.dart';

/// A circular close button with hover effects for modals
class ModalCloseButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ModalCloseButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<ModalCloseButton> createState() => _ModalCloseButtonState();
}

class _ModalCloseButtonState extends State<ModalCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _isHovered
                ? Colors.white
                : Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.3 : 0.2),
                blurRadius: _isHovered ? 12 : 8,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: Icon(
            Icons.close,
            size: 24,
            color: _isHovered ? Colors.black87 : Colors.black54,
          ),
        ),
      ),
    );
  }
}
