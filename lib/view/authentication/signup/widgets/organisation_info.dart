import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/validation_helper.dart';

class OrganisationInfo extends StatelessWidget {
  final TextEditingController organisationNameController;
  final TextEditingController organisationEmailController;
  final TextEditingController organisationPhoneController;
  const OrganisationInfo(
      {super.key,
      required this.organisationNameController,
      required this.organisationEmailController,
      required this.organisationPhoneController});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: organisationNameController,
          decoration: const InputDecoration(
            labelText: 'Organization / Company Name *',
            border: OutlineInputBorder(),
          ),
          validator: (value) =>
              ValidationHelper.validateRequired(value, 'Organization Name'),
        ),
        AppSpacing.verticalMd(context),
        TextFormField(
          controller: organisationEmailController,
          decoration: const InputDecoration(
            labelText: 'Organization Email *',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) => ValidationHelper.validateEmail(value),
        ),
        AppSpacing.verticalMd(context),
        TextFormField(
          controller: organisationPhoneController,
          decoration: const InputDecoration(
            labelText: 'Organization Phone',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
        ),
        AppSpacing.verticalMd(context),
      ],
    );
  }
}
