import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/common_controllers/multi_step_form_controller.dart';
import 'package:traxx_wepapp/models/form_step_model.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

/// Generic multi-step form widget with built-in controller
///
/// This widget provides:
/// - Step navigation with validation
/// - Built-in step management logic
/// - Configurable step indicators
/// - Scroll handling for long forms
/// - Loading states and error handling
class MultiStepFormWidget extends StatefulWidget {
  /// List of form steps
  final List<FormStepModel> steps;

  /// Callback when the entire form is submitted
  final Future<void> Function() onSubmit;

  /// Optional custom step indicators builder
  /// If not provided, default step indicators will be used
  final Widget Function(MultiStepFormController controller)?
      stepIndicatorsBuilder;

  /// Optional custom navigation buttons builder
  /// If not provided, default buttons will be used
  final Widget Function(MultiStepFormController controller)?
      navigationButtonsBuilder;

  /// Maximum width for the form content
  final double maxContentWidth;

  /// Whether to show a scrollbar
  final bool showScrollbar;

  /// Custom padding for the scroll content
  final EdgeInsets? scrollPadding;

  /// Whether to show step indicators
  final bool showStepIndicators;

  const MultiStepFormWidget({
    super.key,
    required this.steps,
    required this.onSubmit,
    this.stepIndicatorsBuilder,
    this.navigationButtonsBuilder,
    this.maxContentWidth = 360,
    this.showScrollbar = true,
    this.scrollPadding,
    this.showStepIndicators = true,
  });

  @override
  State<MultiStepFormWidget> createState() => _MultiStepFormWidgetState();
}

class _MultiStepFormWidgetState extends State<MultiStepFormWidget> {
  final ScrollController _scrollController = ScrollController();
  late MultiStepFormController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MultiStepFormController(
      steps: widget.steps,
      onSubmit: widget.onSubmit,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Form Content - Made Scrollable

        Expanded(
          child: widget.showScrollbar
              ? Scrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  thickness: 8.0,
                  radius: const Radius.circular(4.0),
                  interactive: true,
                  child: _buildScrollContent(),
                )
              : _buildScrollContent(),
        ),

        // Step Indicators
        if (widget.showStepIndicators) ...[
          const SizedBox(height: 24),
          widget.stepIndicatorsBuilder?.call(_controller) ??
              _buildDefaultStepIndicators(),
        ],
      ],
    );
  }

  Widget _buildScrollContent() {
    return Obx(() => SingleChildScrollView(
          controller: _scrollController,
          padding: widget.scrollPadding ??
              const EdgeInsets.only(bottom: 16, right: 16),
          child: SizedBox(
            width: MediaQuery.of(context).size.width < widget.maxContentWidth
                ? MediaQuery.of(context).size.width - 32
                : widget.maxContentWidth,
            child: Column(
              children: [
                // Step header (if provided)
                if (_controller.currentStepModel.header != null) ...[
                  _controller.currentStepModel.header!,
                  const SizedBox(height: 24),
                ],

                // Current step content
                _controller.currentStepModel.form,

                // Error message
                if (_controller.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _controller.errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Navigation Buttons
                const SizedBox(height: 24),
                widget.navigationButtonsBuilder?.call(_controller) ??
                    _buildDefaultNavigationButtons(),
              ],
            ),
          ),
        ));
  }

  /// Default navigation buttons
  Widget _buildDefaultNavigationButtons() {
    return Obx(() {
      final bool hasBackButton = !_controller.isFirstStep;
      final bool isLastStep = _controller.isLastStep;

      return Padding(
        padding: AppPadding.vertical(context, paddingType: Sizes.xs),
        child: SizedBox(
          width: double.infinity,
          child: hasBackButton
              ? Row(
                  children: [
                    // Back Button - takes half width minus 12px
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: _controller.isLoading
                              ? null
                              : _controller.previousStep,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.white,
                            foregroundColor: AppColors.textMuted,
                            side: BorderSide(
                              color: AppColors.borderInput,
                              width: 1.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24), // 24px gap between buttons
                    // Continue/Finish Button - takes half width minus 12px
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _controller.isLoading
                              ? null
                              : _controller.validateAndProceed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _controller.isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(isLastStep ? 'Finish' : 'Continue'),
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _controller.isLoading
                        ? null
                        : _controller.validateAndProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _controller.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isLastStep ? 'Finish' : 'Continue'),
                  ),
                ),
        ),
      );
    });
  }

  /// Default step indicators
  Widget _buildDefaultStepIndicators() {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _controller.totalSteps,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _controller.currentStep == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _controller.currentStep == index ||
                        index < _controller.currentStep
                    ? AppColors.primary
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ));
  }
}
