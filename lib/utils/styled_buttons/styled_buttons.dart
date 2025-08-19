import 'package:flutter/material.dart';

class StyledTextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isPrimary;

  const StyledTextButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: isPrimary
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.errorContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: isPrimary
              ? Theme.of(context).colorScheme.surfaceBright
              : Theme.of(context).colorScheme.error,
        ),
      ),
    );
  }
}
