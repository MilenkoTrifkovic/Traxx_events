import 'package:get/get.dart';
import 'package:traxx_wepapp/models/form_step_model.dart';

/// Controller for managing multi-step form logic
class MultiStepFormController extends GetxController {
  /// List of form steps
  final List<FormStepModel> steps;
  
  /// Callback when the entire form is submitted (after last step)
  final Future<void> Function() onSubmit;
  
  /// Current step index (0-based)
  final RxInt _currentStep = 0.obs;
  
  /// Loading state
  final RxBool _isLoading = false.obs;
  
  /// Error message
  final RxnString _errorMessage = RxnString();

  MultiStepFormController({
    required this.steps,
    required this.onSubmit,
  }) {
    if (steps.isEmpty) {
      throw ArgumentError('Steps list cannot be empty');
    }
  }

  /// Getters
  int get currentStep => _currentStep.value;
  bool get isLoading => _isLoading.value;
  String? get errorMessage => _errorMessage.value;
  
  /// Check if current step is the first step
  bool get isFirstStep => _currentStep.value == 0;
  
  /// Check if current step is the last step
  bool get isLastStep => _currentStep.value == steps.length - 1;
  
  /// Get current step model
  FormStepModel get currentStepModel => steps[_currentStep.value];
  
  /// Get total number of steps
  int get totalSteps => steps.length;
  
  /// Get progress as a value between 0.0 and 1.0
  double get progress => (_currentStep.value + 1) / steps.length;

  /// Move to next step
  void nextStep() {
    if (!isLastStep) {
      _currentStep.value++;
      _clearError();
    }
  }

  /// Move to previous step
  void previousStep() {
    if (!isFirstStep) {
      _currentStep.value--;
      _clearError();
    }
  }

  /// Go to specific step
  void goToStep(int stepIndex) {
    if (stepIndex >= 0 && stepIndex < steps.length) {
      _currentStep.value = stepIndex;
      _clearError();
    }
  }

  /// Validate current step and proceed
  Future<void> validateAndProceed() async {
    if (_isLoading.value) return;

    try {
      _clearError();
      
      // Call the current step's validation callback
      final isValid = currentStepModel.onContinue();
      
      if (isValid) {
        if (isLastStep) {
          // Last step - submit the form
          await _handleSubmit();
        } else {
          // Move to next step
          nextStep();
        }
      }
      // If validation fails, the step's onContinue should handle showing error messages
    } catch (e) {
      _setError('Validation error: $e');
    }
  }

  /// Handle form submission
  Future<void> _handleSubmit() async {
    try {
      _setLoading(true);
      await onSubmit();
      // Success - the onSubmit callback should handle navigation
    } catch (e) {
      _setError('Submission failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading.value = loading;
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage.value = message;
  }

  /// Clear error message
  void _clearError() {
    _errorMessage.value = null;
  }

  /// Reset form to first step
  void reset() {
    _currentStep.value = 0;
    _isLoading.value = false;
    _clearError();
  }

  /// Check if a specific step can be accessed (useful for step indicators)
  bool canAccessStep(int stepIndex) {
    // Allow access to current step and all previous steps
    return stepIndex <= _currentStep.value;
  }

  @override
  void onClose() {
    _currentStep.close();
    _isLoading.close();
    _errorMessage.close();
    super.onClose();
  }
}