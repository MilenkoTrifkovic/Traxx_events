import 'package:flutter/material.dart';
import 'package:traxx_wepapp/widgets/app_bar.dart';

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String role;
  final String name;
  final VoidCallback? onProfilePress;
  final VoidCallback? onLogout;

  const AppScaffold({
    super.key,
    required this.body,
    required this.role,
    required this.name,
    this.onProfilePress,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(
        role,
        'WELCOME $name',
        context,
        profilePress: onProfilePress,
        logout: onLogout,
      ),
      body: body,
    );
  }
}
