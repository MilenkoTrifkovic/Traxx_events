import 'package:flutter/material.dart';

/// Model representing a single step in a multi-step form
class FormStepModel {
  /// The form widget for this step
  final Widget form;
  
  /// Callback to validate and continue from this step
  /// Should return true if validation passes and can proceed to next step
  final bool Function() onContinue;
  
  /// Optional header widget for this step
  final Widget? header;

  const FormStepModel({
    required this.form,
    required this.onContinue,
    this.header,
  });
}