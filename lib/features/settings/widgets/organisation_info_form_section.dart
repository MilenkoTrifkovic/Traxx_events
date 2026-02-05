import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/validation_helper.dart';
import 'package:traxx_wepapp/features/settings/controllers/settings_screen_controller.dart';
import 'package:traxx_wepapp/controller/global_controllers/organisation_controller.dart';
import 'package:traxx_wepapp/widgets/app_text_input_field.dart';
import 'package:traxx_wepapp/widgets/app_dropdown_menu.dart';
import 'package:traxx_wepapp/widgets/app_primary_button.dart';
import 'package:traxx_wepapp/widgets/app_secondary_button.dart';
import 'package:traxx_wepapp/utils/data/us_data.dart';
import 'package:traxx_wepapp/utils/money_helper.dart';

/// Right-hand organisation info form and action buttons (Save/Cancel).
class OrganisationInfoFormSection extends StatelessWidget {
  final SettingsScreenController controller;
  final OrganisationController organisationController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  OrganisationInfoFormSection({
    super.key,
    required this.controller,
    required this.organisationController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = ScreenSize.isDesktop(context);
      // double columnWidth = (constraints.maxWidth - 24) / 2;
      //     columnWidth = math.min(columnWidth, 360);
      //bug fix
      double columnWidth = math.max(0, (constraints.maxWidth - 24) / 2);
      columnWidth = math.min(columnWidth, 360);

      Widget wrapChild(Widget child) => SizedBox(
            width: isDesktop ? math.min(columnWidth, 360) : double.infinity,
            child: child,
          );

      return Obx(() {
        final List<Widget> fields = [
          wrapChild(Obx(() => AppTextInputField(
                label: 'Company Name',
                controller: controller.companyNameController,
                hintText: 'Company name',
                enabled: controller.isEditing.value,
                validator: (v) => ValidationHelper.validateCompanyName(v),
              ))),
          wrapChild(Obx(() => AppTextInputField(
                label: 'Phone',
                controller: controller.phoneController,
                hintText: 'Phone number',
                enabled: controller.isEditing.value,
                validator: (v) => ValidationHelper.validatePhoneNumber(v),
              ))),
          wrapChild(Obx(() => AppTextInputField(
                label: 'Address',
                controller: controller.addressController,
                hintText: 'Street address',
                enabled: controller.isEditing.value,
                validator: (v) => ValidationHelper.validateAddress(v),
              ))),
          wrapChild(Obx(() => AppTextInputField(
                label: 'Website',
                controller: controller.websiteController,
                hintText: 'Website (optional)',
                enabled: controller.isEditing.value,
                validator: (v) => ValidationHelper.validateOptionalWebsite(v),
              ))),
          wrapChild(Obx(() => AppTextInputField(
                label: 'City',
                controller: controller.cityController,
                hintText: 'City',
                enabled: controller.isEditing.value,
                validator: (v) => ValidationHelper.validateCity(v),
              ))),
          wrapChild(Obx(() => AppTextInputField(
                label: 'Zip Code',
                controller: controller.zipController,
                hintText: 'Zip code',
                enabled: controller.isEditing.value,
                validator: (v) => ValidationHelper.validateZipCode(v),
              ))),
          wrapChild(Obx(() => AppDropdownMenu<String>(
                label: 'Timezone',
                value: controller.selectedTimezone.value,
                hintText: 'Select timezone',
                enabled: controller.isEditing.value,
                enableSearch: true,
                searchExtractor: (timezone) => timezone,
                items: USData.timezones
                    .map((tz) => DropdownMenuItem<String>(
                          value: tz,
                          child: Text(tz),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.selectedTimezone.value = v;
                },
                validator: (v) =>
                    ValidationHelper.validateDropdownSelection(v, 'timezone'),
              ))),
          wrapChild(Obx(() => AppDropdownMenu<String>(
                label: 'Country',
                value: controller.selectedCountry.value,
                hintText: 'Select country',
                enabled: controller.isEditing.value,
                enableSearch: true,
                searchExtractor: (country) => country,
                items: USData.countries
                    .map((c) => DropdownMenuItem<String>(
                          value: c,
                          child: Text(c),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.selectedCountry.value = v;
                },
                validator: (v) =>
                    ValidationHelper.validateDropdownSelection(v, 'country'),
              ))),
          // State dropdown - Only for United States (reactive to country changes)
          // Use conditional spread operator to completely exclude from list when not USA
          ...controller.selectedCountry.value == 'United States'
              ? [
                  wrapChild(Obx(() => AppDropdownMenu<String>(
                        label: 'State',
                        value: controller.selectedState.value,
                        hintText: 'Select state',
                        enabled: controller.isEditing.value,
                        enableSearch: true,
                        searchExtractor: (state) => state,
                        items: USData.states
                            .map((s) => DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) controller.selectedState.value = v;
                        },
                        validator: (v) =>
                            ValidationHelper.validateDropdownSelection(
                                v, 'state'),
                      )))
                ]
              : [],
          wrapChild(Obx(() => AppDropdownMenu<String>(
                label: 'Currency',
                value: controller.selectedCurrency.value,
                hintText: 'Select currency',
                enabled: controller.isEditing.value,
                items: MoneyHelper.commonCurrencyCodes.map((code) {
                  final symbol = MoneyHelper.getSymbol(code);
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text('$code ($symbol)'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) controller.selectedCurrency.value = v;
                },
                validator: (v) =>
                    ValidationHelper.validateDropdownSelection(v, 'currency'),
              ))),
        ];

        return Form(
          key: _formKey,
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isDesktop)
                Wrap(spacing: 24, runSpacing: 0, children: fields)
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: fields
                      .map((w) => Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: w,
                          ))
                      .toList(),
                ),
              // ✅ Toggle row
              Obx(() {
                final showPrices = organisationController
                    .showMenuItemPrices.value; // ✅ true = show
                final hidePrices = !showPrices; // ✅ switch represents "hide"
                final saving = organisationController.isLoading.value;

                return Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hide menu items price',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Applies across menus, event details, and selection popup.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: hidePrices, // ✅ inverted
                        onChanged: saving
                            ? null
                            : (hide) => organisationController
                                .updateShowMenuItemPrices(!hide),
                        //                ✅ store showMenuItemPrices
                      ),
                    ],
                  ),
                );
              }),

              AppSpacing.verticalSm(context),
              // Actions: align the buttons' right edge with the form fields above.
              // On phones keep full-width behavior; on larger layouts constrain the
              // actions container to the same content width as the two-column form.
              if (!isDesktop)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Obx(() {
                      if (controller.isEditing.value) {
                        return AppSecondaryButton(
                          text: 'Cancel',
                          onPressed: () {
                            controller.cancelEditing();
                          },
                        );
                      }
                      return AppSecondaryButton(
                        text: 'Edit',
                        onPressed: () {
                          controller.startEditing();
                        },
                      );
                    }),
                    const SizedBox(width: 12),
                    Obx(() {
                      final isLoading = organisationController.isLoading.value;
                      return AppPrimaryButton(
                        text: 'Save Change',
                        isLoading: isLoading,
                        onPressed: (!controller.isEditing.value || isLoading)
                            ? null
                            : () async {
                                final valid =
                                    _formKey.currentState?.validate() ?? false;
                                if (!valid) return;
                                await controller.updateOrganisation();
                              },
                      );
                    }),
                  ],
                )
              else
                // For non-phone layouts, limit the width of the actions container to
                // the combined width of two form columns plus the spacing between them
                // so the buttons line up with the form fields above.
                Container(
                  // width: math.min(columnWidth * 2 + 24, constraints.maxWidth),
                  // bug fix
                  width: math.max(
                    0,
                    math.min(columnWidth * 2 + 24, constraints.maxWidth),
                  ),

                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Obx(() {
                        if (controller.isEditing.value) {
                          return AppSecondaryButton(
                            text: 'Cancel',
                            onPressed: () {
                              controller.cancelEditing();
                            },
                          );
                        }
                        return AppSecondaryButton(
                          text: 'Edit',
                          onPressed: () {
                            controller.startEditing();
                          },
                        );
                      }),
                      const SizedBox(width: 12),
                      Obx(() {
                        final isLoading =
                            organisationController.isLoading.value;
                        return AppPrimaryButton(
                          text: 'Save Change',
                          isLoading: isLoading,
                          onPressed: (!controller.isEditing.value || isLoading)
                              ? null
                              : () async {
                                  final valid =
                                      _formKey.currentState?.validate() ??
                                          false;
                                  if (!valid) return;
                                  await controller.updateOrganisation();
                                },
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
        );
      });
    });
  }
}
