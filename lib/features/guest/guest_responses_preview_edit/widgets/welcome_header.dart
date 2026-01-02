import 'package:flutter/material.dart';

/// Welcome header widget displaying guest name
class WelcomeHeader extends StatelessWidget {
  final String guestName;

  const WelcomeHeader({
    super.key,
    required this.guestName,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      'Welcome back, $guestName!',
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }
}
