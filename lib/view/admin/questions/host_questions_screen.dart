// lib/views/host_questions_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:traxx_wepapp/controller/admin_controllers/host_questions_controller.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/models/host_questions_option.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

class HostQuestionsScreen extends StatefulWidget {
  const HostQuestionsScreen({super.key});

  @override
  State<HostQuestionsScreen> createState() => _HostQuestionsScreenState();
}

class _HostQuestionsScreenState extends State<HostQuestionsScreen>
    with SingleTickerProviderStateMixin {
  late final HostQuestionsController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        HostQuestionsController(firestore: FirebaseFirestore.instance);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: AppSpacing.md(context),
        bottom: AppSpacing.lg(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnimatedHeader(context),
          AppSpacing.verticalLg(context),
          _buildQuestionsStream(),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Header with subtle gradient + icon animation
  // ────────────────────────────────────────────────────────────────
  Widget _buildAnimatedHeader(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.1),
              AppColors.secondary.withOpacity(0.08),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.borderHover),
        ),
        child: Row(
          children: [
            // animated icon bubble
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
              ),
              child: Icon(
                Icons.quiz_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.styledHeadingMedium(
                    context,
                    'Demographic Questions',
                    color: Colors.black,
                  ),
                  const SizedBox(height: 4),
                  AppText.styledBodySmall(
                    context,
                    'Design beautiful RSVP & survey experiences. '
                    'Questions and options below are loaded live from Firestore.',
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // StreamBuilder → listens to Firestore via controller
  // ────────────────────────────────────────────────────────────────
  Widget _buildQuestionsStream() {
    return StreamBuilder<List<DemographicQuestionWithOptions>>(
      stream: _controller.streamQuestions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSkeleton(context);
        }

        if (snapshot.hasError) {
          final err = snapshot.error;

          if (kDebugMode) {
            if (err is FirebaseException) {
              // This will include the "create index" URL for Firestore web
              print(
                  '🔥 Firestore error in HostQuestionsScreen: ${err.code} – ${err.message}');
              print('🔥 Full error: $err');
            } else {
              print('🔥 Unknown error in HostQuestionsScreen: $err');
            }
          }

          return _buildErrorState(context, err.toString());
        }

        final items = snapshot.data ?? [];

        if (items.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: [
            for (int i = 0; i < items.length; i++)
              _buildAnimatedQuestionCard(items[i], i),
          ],
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Animated question card
  // ────────────────────────────────────────────────────────────────
  Widget _buildAnimatedQuestionCard(
    DemographicQuestionWithOptions item,
    int index,
  ) {
    final question = item.question;
    final options = item.options;

    final Color accentColor = _categoryColor(question.questionCategory);
    final IconData iconData =
        _categoryIcon(question.questionCategory, question.questionType);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 450 + index * 80),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: _HoverCard(
        margin: EdgeInsets.only(
          bottom: AppSpacing.md(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: icon + question text + chips
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon bubble
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.15),
                  ),
                  child: Icon(
                    iconData,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.styledBodyLarge(
                        context,
                        question.questionText,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildTagChip(
                            label: question.questionCategory.isEmpty
                                ? 'General'
                                : question.questionCategory,
                            icon: Icons.category_rounded,
                            color: accentColor.withOpacity(0.12),
                            textColor: accentColor,
                          ),
                          _buildTagChip(
                            label: question.questionType,
                            icon: Icons.tune_rounded,
                            color: AppColors.chipBackground,
                            textColor: AppColors.secondary,
                          ),
                          if (question.isRequired)
                            _buildTagChip(
                              label: 'Required',
                              icon: Icons.star_rounded,
                              color: Colors.red.withOpacity(0.08),
                              textColor: Colors.red.shade600,
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Divider with subtle gradient
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.borderHover,
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Options rendered as animated pills
            if (options.isEmpty)
              AppText.styledBodySmall(
                context,
                'No options configured yet for this question.',
                color: AppColors.secondary,
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((opt) {
                  return _buildOptionPill(opt, accentColor);
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Option pill with slight hover animation
  // ────────────────────────────────────────────────────────────────
  Widget _buildOptionPill(DemographicQuestionOption opt, Color accentColor) {
    final bool hasText = opt.requiresFreeText;

    return _HoverCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      radius: 999,
      elevation: 2,
      borderColor: accentColor.withOpacity(0.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasText ? Icons.edit_note_rounded : Icons.check_circle_rounded,
            size: 18,
            color: accentColor,
          ),
          const SizedBox(width: 8),
          Text(
            opt.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          if (hasText) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Free text',
                style: TextStyle(fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Loading / Empty / Error
  // ────────────────────────────────────────────────────────────────
  Widget _buildLoadingSkeleton(BuildContext context) {
    // simple animated shimmer-like placeholders
    return Column(
      children: List.generate(
        3,
        (index) => TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 500 + index * 120),
          tween: Tween(begin: 0, end: 1),
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: child,
          ),
          child: _HoverCard(
            margin: EdgeInsets.only(bottom: AppSpacing.md(context)),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.skeletonBase,
                    AppColors.skeletonHighlight,
                    AppColors.skeletonBase,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.95 + 0.05 * value,
            child: child,
          ),
        );
      },
      child: _HoverCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // you can replace this with a Lottie later
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryAccent.withOpacity(0.08),
              ),
              child: Icon(
                Icons.help_outline_rounded,
                size: 48,
                color: AppColors.primaryAccent,
              ),
            ),
            const SizedBox(height: 16),
            AppText.styledBodyLarge(
              context,
              'No questions yet',
              color: Colors.black,
            ),
            const SizedBox(height: 6),
            AppText.styledBodySmall(
              context,
              'Start by adding your first demographic question.\n'
              'Click “Add Question” in the top-right.',
              color: AppColors.secondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return _HoverCard(
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: AppText.styledBodySmall(
              context,
              'Failed to load questions: $error',
              color: Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Small pill-style chip used for category / type / required
  Widget _buildTagChip({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────
  // Helpers: category → color / icon
  // ────────────────────────────────────────────────────────────────
  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'dietary':
        return Colors.green.shade600;
      case 'accessibility':
        return Colors.deepPurple.shade500;
      case 'profile':
        return Colors.blue.shade600;
      case 'travel':
        return Colors.orange.shade600;
      default:
        return AppColors.primary;
    }
  }

  IconData _categoryIcon(String category, String type) {
    final c = category.toLowerCase();
    if (c == 'dietary') return Icons.restaurant_menu_rounded;
    if (c == 'accessibility') return Icons.accessibility_new_rounded;
    if (c == 'profile') return Icons.person_rounded;
    if (c == 'travel') return Icons.flight_takeoff_rounded;

    if (type == 'multi_select') return Icons.checklist_rounded;
    if (type == 'single_select') return Icons.radio_button_checked_rounded;
    if (type == 'text') return Icons.short_text_rounded;

    return Icons.help_outline_rounded;
  }
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double radius;
  final double elevation;
  final Color? borderColor;

  const _HoverCard({
    required this.child,
    this.padding,
    this.margin,
    this.radius = 16,
    this.elevation = 4,
    this.borderColor,
  });

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final padding = widget.padding ??
        const EdgeInsets.symmetric(horizontal: 20, vertical: 18);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 4),
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(
            color: widget.borderColor ??
                (_hovering ? AppColors.borderHoverDark : AppColors.borderHover),
          ),
          boxShadow: [
            if (_hovering)
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                offset: const Offset(0, 10),
                blurRadius: 24,
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                offset: const Offset(0, 4),
                blurRadius: 10,
              )
          ],
        ),
        child: widget.child,
      ),
    );
  }
}
