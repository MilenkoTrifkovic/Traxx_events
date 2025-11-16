import 'package:flutter/material.dart';

class SignupFormControllers {
  // Initialize Admin Info Controllers
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  // Initialize Organization Info Controllers
  final organizationNameController = TextEditingController();
  final organizationEmailController = TextEditingController();
  final organizationPhoneController = TextEditingController();
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final zipController = TextEditingController();
  final countryController = TextEditingController();
  final websiteController = TextEditingController();

  void dispose() {
    // Dispose Admin Info Controllers
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    // Dispose Organization Info Controllers
    organizationNameController.dispose();
    organizationEmailController.dispose();
    organizationPhoneController.dispose();
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    zipController.dispose();
    countryController.dispose();
    websiteController.dispose();
  }
}
