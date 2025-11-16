import 'package:flutter/material.dart';

class OrganisationFormKeys {
  static final GlobalKey<FormState> locationTimeFormKey =
      GlobalKey<FormState>();
  static final GlobalKey<FormState> restaurantInfoFormKey =
      GlobalKey<FormState>();

  static bool validateCurrentStep(int currentStep) {
    switch (currentStep) {
      case 0:
        return locationTimeFormKey.currentState?.validate() ?? false;
      case 1:
        return restaurantInfoFormKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }
}
