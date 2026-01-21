import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return _PoppinsScope(
      child: Form(
        key: OrganisationFormKeys.locationTimeFormKey,
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: _responsiveFormMaxWidth(context)),
            child: LayoutBuilder(
              builder: (context, c) {
                final isPhone = c.maxWidth < 600;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      icon: Icons.location_on,
                      title: 'Location & Time',
                      description:
                          'Tell us more about where the customers can find you',
                    ),
                    const SizedBox(height: 18),

                    // Address
                    AppTextInputField(
                      label: 'Address',
                      controller: controller.addressController,
                      hintText: 'Start typing your address...',
                      validator: ValidationHelper.validateAddress,
                      width: double.infinity,
                    ),
                    const SizedBox(height: 16),

                    // City + Country row on wide, stacked on phone
                    if (isPhone) ...[
                      AppTextInputField(
                        label: 'City',
                        controller: controller.cityController,
                        hintText: 'Enter city',
                        validator: ValidationHelper.validateCity,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 16),
                      Obx(() => AppDropdownMenu<String>(
                            label: 'Country',
                            value: controller.selectedCountry.value,
                            hintText: 'Select country',
                            enableSearch: true,
                            searchExtractor: (country) => country,
                            validator: (value) =>
                                ValidationHelper.validateDropdownSelection(
                                    value, 'country'),
                            items: USData.countries.map((String country) {
                              return DropdownMenuItem<String>(
                                value: country,
                                child:
                                    Text(country, style: GoogleFonts.poppins()),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                controller.selectedCountry.value = newValue;
                              }
                            },
                          )),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: AppTextInputField(
                              label: 'City',
                              controller: controller.cityController,
                              hintText: 'Enter city',
                              validator: ValidationHelper.validateCity,
                              width: double.infinity,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Obx(() => AppDropdownMenu<String>(
                                  label: 'Country',
                                  value: controller.selectedCountry.value,
                                  hintText: 'Select country',
                                  enableSearch: true,
                                  searchExtractor: (country) => country,
                                  validator: (value) => ValidationHelper
                                      .validateDropdownSelection(
                                          value, 'country'),
                                  items: USData.countries.map((String country) {
                                    return DropdownMenuItem<String>(
                                      value: country,
                                      child: Text(country,
                                          style: GoogleFonts.poppins()),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      controller.selectedCountry.value =
                                          newValue;
                                    }
                                  },
                                )),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // State (only US) + Zip (always) - responsive
                    Obx(() {
                      final isUS =
                          controller.selectedCountry.value == 'United States';

                      if (isPhone) {
                        return Column(
                          children: [
                            if (isUS) ...[
                              AppDropdownMenu<String>(
                                label: 'State',
                                value: controller.selectedState.value,
                                hintText: 'Select state',
                                enableSearch: true,
                                searchExtractor: (state) => state,
                                validator: (value) =>
                                    ValidationHelper.validateDropdownSelection(
                                        value, 'state'),
                                items: USData.states.map((String state) {
                                  return DropdownMenuItem<String>(
                                    value: state,
                                    child: Text(state,
                                        style: GoogleFonts.poppins()),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    controller.selectedState.value = newValue;
                                  }
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            AppTextInputField(
                              label: 'Zip Code',
                              controller: controller.zipController,
                              hintText: 'Enter zip code',
                              validator: ValidationHelper.validateZipCode,
                              width: double.infinity,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          if (isUS) ...[
                            Expanded(
                              child: AppDropdownMenu<String>(
                                label: 'State',
                                value: controller.selectedState.value,
                                hintText: 'Select state',
                                enableSearch: true,
                                searchExtractor: (state) => state,
                                validator: (value) =>
                                    ValidationHelper.validateDropdownSelection(
                                        value, 'state'),
                                items: USData.states.map((String state) {
                                  return DropdownMenuItem<String>(
                                    value: state,
                                    child: Text(state,
                                        style: GoogleFonts.poppins()),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    controller.selectedState.value = newValue;
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: AppTextInputField(
                              label: 'Zip Code',
                              controller: controller.zipController,
                              hintText: 'Enter zip code',
                              validator: ValidationHelper.validateZipCode,
                              width: double.infinity,
                            ),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 16),

                    // Timezone
                    Obx(() => AppDropdownMenu<String>(
                          label: 'Timezone',
                          value: controller.selectedTimezone.value,
                          hintText: 'Select timezone',
                          enableSearch: true,
                          searchExtractor: (timezone) => timezone,
                          validator: (value) =>
                              ValidationHelper.validateDropdownSelection(
                                  value, 'timezone'),
                          items: USData.timezones.map((String timezone) {
                            return DropdownMenuItem<String>(
                              value: timezone,
                              child:
                                  Text(timezone, style: GoogleFonts.poppins()),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              controller.selectedTimezone.value = newValue;
                            }
                          },
                        )),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PoppinsScope extends StatelessWidget {
  final Widget child;
  const _PoppinsScope({required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
        primaryTextTheme: GoogleFonts.poppinsTextTheme(base.primaryTextTheme),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          labelStyle: GoogleFonts.poppins(),
          hintStyle: GoogleFonts.poppins(),
          floatingLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      child: DefaultTextStyle(
        style: GoogleFonts.poppins(),
        child: child,
      ),
    );
  }
}

double _responsiveFormMaxWidth(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 600) return double.infinity; // phone: full width
  if (w < 1100) return 520; // tablet
  return 720; // desktop
}
