import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/view/admin/organisation_info_popup/widgets/section_header.dart';
import 'package:traxx_wepapp/utils/data/us_data.dart';
import 'package:traxx_wepapp/helper/validation_helper.dart';
import 'package:traxx_wepapp/utils/organisation_form_keys.dart';
import 'package:traxx_wepapp/controller/admin_controllers/organisation_info_controller.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';
import 'package:traxx_wepapp/widgets/app_dropdown_menu.dart';

class LocationTimeForm extends StatefulWidget {
  const LocationTimeForm({super.key});

  @override
  State<LocationTimeForm> createState() => _LocationTimeFormState();
}

class _LocationTimeFormState extends State<LocationTimeForm> {
  late final OrganisationInfoController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OrganisationInfoController>();
  }

  bool validateForm() {
    return OrganisationFormKeys.locationTimeFormKey.currentState?.validate() ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: OrganisationFormKeys.locationTimeFormKey,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SectionHeader(
              icon: Icons.location_on,
              title: 'Location & Time',
              description:
                  'Tell us more about where the customers can find you',
            ),

            // Address Field
            Column(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppTextInputField(
                        label: 'Address',
                        controller: controller.addressController,
                        hintText: 'Start typing your address...',
                        validator: ValidationHelper.validateAddress,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // City Field
                AppTextInputField(
                  label: 'City',
                  controller: controller.cityController,
                  hintText: 'Enter city',
                  validator: ValidationHelper.validateCity,
                ),
                const SizedBox(height: 16),

                // Country Dropdown
                Obx(() => AppDropdownMenu<String>(
                      label: 'Country',
                      value: controller.selectedCountry.value,
                      hintText: 'Select country',
                      validator: (value) =>
                          ValidationHelper.validateDropdownSelection(
                              value, 'country'),
                      items: USData.countries.map((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Text(country),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          controller.selectedCountry.value = newValue;
                        }
                      },
                    )),
                const SizedBox(height: 16),

                // State and Zip Row
                Row(
                  children: [
                    // State Dropdown
                    Expanded(
                      child: Obx(() => AppDropdownMenu<String>(
                            label: 'State',
                            value: controller.selectedState.value,
                            hintText: 'Select state',
                            validator: (value) =>
                                ValidationHelper.validateDropdownSelection(
                                    value, 'state'),
                            items: USData.states.map((String state) {
                              return DropdownMenuItem<String>(
                                value: state,
                                child: Text(state),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                controller.selectedState.value = newValue;
                              }
                            },
                          )),
                    ),
                    const SizedBox(width: 16),
                    // Zip Field
                    Expanded(
                      child: AppTextInputField(
                        label: 'Zip Code',
                        controller: controller.zipController,
                        hintText: 'Enter zip code',
                        validator: ValidationHelper.validateZipCode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Timezone Dropdown
                Obx(() => AppDropdownMenu<String>(
                      label: 'Timezone',
                      value: controller.selectedTimezone.value,
                      hintText: 'Select timezone',
                      validator: (value) =>
                          ValidationHelper.validateDropdownSelection(
                              value, 'timezone'),
                      items: USData.timezones.map((String timezone) {
                        return DropdownMenuItem<String>(
                          value: timezone,
                          child: Text(timezone),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          controller.selectedTimezone.value = newValue;
                        }
                      },
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
