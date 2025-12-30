import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/helper/validation_helper.dart';
import 'package:traxx_wepapp/utils/enums/genders.dart';

/// Data model for managing companion form state
class CompanionFormData {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController city = TextEditingController();
  final RxnString selectedCountry = RxnString();
  final RxnString selectedState = RxnString();
  final Rxn<Gender> selectedGender = Rxn<Gender>();
  String? createdGuestId; // Store the created guest ID

  void dispose() {
    name.dispose();
    email.dispose();
    address.dispose();
    city.dispose();
  }

  void clear() {
    name.clear();
    email.clear();
    address.clear();
    city.clear();
    selectedCountry.value = null;
    selectedState.value = null;
    selectedGender.value = null;
    createdGuestId = null;
  }

  bool validate() {
    // Try form validation first (works if form is in widget tree)
    final formValid = formKey.currentState?.validate() ?? false;
    if (formValid) return true;
    
    // If form is not in widget tree, manually validate required fields
    // Required fields: name and email
    final nameValid = name.text.trim().isNotEmpty;
    final emailText = email.text.trim();
    final emailValid = emailText.isNotEmpty && 
        ValidationHelper.validateEmail(emailText) == null; // null means valid
    
    return nameValid && emailValid;
  }
}

