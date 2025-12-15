import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:traxx_wepapp/forms/signup_form/signup_form_controllers.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/view/authentication/signup/widgets/admin_info_section.dart';
import 'package:traxx_wepapp/view/authentication/signup/widgets/organisation_address.dart';
import 'package:traxx_wepapp/view/authentication/signup/widgets/organisation_info.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  State<SignupView> createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  final _formKey = GlobalKey<FormState>();
  late final SignupFormControllers _signupFormControllers =
      SignupFormControllers();

  @override
  void initState() {
    super.initState();

    // Initialize Admin Info Controllers
  }

  @override
  void dispose() {
    // Dispose Admin Info Controllers
    _signupFormControllers.dispose();
    super.dispose();
  }

  // void _submitForm() async {
  //   if (_formKey.currentState!.validate()) {
  //     try {
  //       final authController = Get.find<AuthController>();

  //       await authController.createOrganisation(
  //         name: _signupFormControllers.organizationNameController.text,
  //         phone:
  //             _signupFormControllers.organizationPhoneController.text.isNotEmpty
  //                 ? _signupFormControllers.organizationPhoneController.text
  //                 : 'Not provided', // Provide a default since it's required
  //         website: _signupFormControllers.websiteController.text.isEmpty
  //             ? null
  //             : _signupFormControllers.websiteController.text,
  //         street: _signupFormControllers.streetController.text,
  //         city: _signupFormControllers.cityController.text,
  //         state: _signupFormControllers.stateController.text,
  //         zip: _signupFormControllers.zipController.text,
  //         country: _signupFormControllers.countryController.text,
  //         timezone: 'UTC', // Provide default timezone since it's required
  //         logo: null, // Optional logo parameter
  //       );

  //       // Show success message
  //       SnackBarUtils.showSuccess(
  //           context, 'Organisation created successfully!');
  //     } catch (e) {
  //       // Show error message
  //       SnackBarUtils.showError(context, 'Error creating organisation: $e');
  //     }
  //   }
  // }

  void _createAdminAccount() {
    final functions = FirebaseFunctions.instance;

    if (kDebugMode) {
      // Samo u developmentu koristi emulator
      functions.useFunctionsEmulator("localhost", 5001);
    }
    functions.httpsCallable('addOrganisation').call({
      'name': 'Test Restaurant BBQ',
      'email': 'test@restaurant.com',
      'phone': '+1-555-123-4567',
      'website': 'https://testrestaurant.com',
      'timezone': 'America/Chicago',
      'address': {
        'street': '123 Main Street',
        'city': 'Austin',
        'state': 'TX',
        'zip': '73301',
        'country': 'USA',
      },
    });
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
        padding: AppPadding.vertical(context, paddingType: Sizes.sm),
        child:
            AppText.styledBodyLarge(context, title, weight: FontWeight.bold));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin / Account Info Section
            _buildSectionTitle('👤 Admin / Account Info'),
            AdminInfoSection(
              firstNameController: _signupFormControllers.firstNameController,
              lastNameController: _signupFormControllers.lastNameController,
              emailController: _signupFormControllers.emailController,
              phoneController: _signupFormControllers.phoneController,
            ),

            // Organization Info Section
            _buildSectionTitle('🏢 Organization Info'),

            OrganisationInfo(
                organisationNameController:
                    _signupFormControllers.organizationNameController,
                organisationEmailController:
                    _signupFormControllers.emailController,
                organisationPhoneController:
                    _signupFormControllers.organizationPhoneController),
            // Address Section
            _buildSectionTitle('📍 Organization Address'),
            OrganisationAddress(
              streetController: _signupFormControllers.streetController,
              cityController: _signupFormControllers.cityController,
              stateController: _signupFormControllers.stateController,
              zipController: _signupFormControllers.zipController,
              countryController: _signupFormControllers.countryController,
              websiteController: _signupFormControllers.websiteController,
            ),
            AppSpacing.verticalMd(context),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createAdminAccount,
                // onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Create Admin Account',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
