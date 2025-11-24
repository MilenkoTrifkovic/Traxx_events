import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/view/authentication/login/widgets/welcome_background.dart';

/// A reusable scaffold with full-screen background image and transparent content wrapper
///
/// This widget provides a consistent layout pattern for screens that need:
/// - Full-screen background image
/// - Transparent content overlay
/// - Responsive content wrapper
///
/// Usage:
/// ```dart
/// BackgroundScaffold(
///   child: YourContentWidget(),
/// )
/// ```
class BackgroundScaffold extends StatelessWidget {
  /// The main content to display over the background
  final Widget child;

  /// Optional app bar widget
  final PreferredSizeWidget? appBar;

  /// Whether to extend the body behind the app bar
  final bool extendBodyBehindAppBar;

  /// Background color for the scaffold (shows if background image fails to load)
  final Color? backgroundColor;

  /// Optional maximum width for the content wrapper
  final double? maxWidth;

  /// Alignment for the content wrapper
  final Alignment contentAlignment;

  const BackgroundScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.extendBodyBehindAppBar = true,
    this.backgroundColor,
    this.maxWidth,
    this.contentAlignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: backgroundColor ?? AppColors.borderSubtle,
      appBar: appBar,
      body: Stack(
        children: [
          // Full Screen Background Layer
          const Positioned.fill(
            child: WelcomeBackground(),
          ),
          // Content Layer with wrapper
          child,
        ],
      ),
    );
    // return Scaffold(
    //   extendBodyBehindAppBar: extendBodyBehindAppBar,
    //   backgroundColor: backgroundColor ?? AppColors.borderSubtle,
    //   appBar: appBar,
    //   body: Stack(
    //     children: [
    //       // Full Screen Background Layer
    //       const Positioned.fill(
    //         child: WelcomeBackground(),
    //       ),
    //       // Content Layer with wrapper
    //       ContentWrapper(
    //         contentColor:
    //             Colors.transparent, // Make content wrapper transparent
    //         shadow: const BoxShadow(color: Colors.transparent), // Remove shadow
    //         maxWidth: maxWidth ?? 1440, // Default or custom max width
    //         alignment: contentAlignment,
    //         child: child,
    //       ),
    //     ],
    //   ),
    // );
  }
}
