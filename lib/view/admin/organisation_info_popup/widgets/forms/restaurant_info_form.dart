import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/view/admin/organisation_info_popup/widgets/section_header.dart';
import 'package:traxx_wepapp/helper/validation_helper.dart';
import 'package:traxx_wepapp/utils/organisation_form_keys.dart';
import 'package:traxx_wepapp/controller/admin_controllers/organisation_info_controller.dart';

class RestaurantInfoForm extends StatefulWidget {
  const RestaurantInfoForm({super.key});

  @override
  State<RestaurantInfoForm> createState() => _RestaurantInfoFormState();
}

class _RestaurantInfoFormState extends State<RestaurantInfoForm> {
  late final OrganisationInfoController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<OrganisationInfoController>();
  }

  @override
  Widget build(BuildContext context) {
    return _PoppinsScope(
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;

          // nice readable width for forms
          final maxFormWidth = w < 600 ? w : (w < 1100 ? 560.0 : 720.0);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxFormWidth),
              child: Form(
                key: OrganisationFormKeys.restaurantInfoFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      icon: Icons.restaurant,
                      title: 'Restaurant Info',
                      description:
                          'Provide basic information about your restaurant.',
                    ),
                    const SizedBox(height: 24),
                    _NewRestaurantForm(controller: controller),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Only "new restaurant" form remains
class _NewRestaurantForm extends StatelessWidget {
  final OrganisationInfoController controller;

  const _NewRestaurantForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final isPhone = w < 600;

        final cardPad = isPhone ? 16.0 : 20.0;
        final fieldGap = isPhone ? 16.0 : 20.0;

        // Logo area width: full on phone, fixed on larger screens
        final logoW = isPhone ? w : 260.0;
        final logoH = 180.0;

        InputDecoration deco(String hint, {String? prefixText}) {
          return InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  BorderSide(color: AppColors.primaryAccent, width: 1.2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          );
        }

        Widget label(String text, {Widget? trailing}) {
          return Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          );
        }

        return Container(
          padding: EdgeInsets.all(cardPad),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1) Logo upload (responsive width)
              Center(
                child: SizedBox(
                  width: logoW,
                  child: Column(
                    children: [
                      SizedBox(
                        height: logoH,
                        child: Obx(
                          () => Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: controller.selectedImagePath.value == null
                                ? InkWell(
                                    onTap: controller.selectLogo,
                                    borderRadius: BorderRadius.circular(14),
                                    child: Center(
                                      child: Icon(
                                        Icons.photo_library_outlined,
                                        size: 46,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  )
                                : Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: kIsWeb
                                            ? Image.network(
                                                controller
                                                    .selectedImagePath.value!,
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    _fallbackLogoBox(),
                                              )
                                            : Image.file(
                                                File(controller
                                                    .selectedImagePath.value!),
                                                width: double.infinity,
                                                height: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    _fallbackLogoBox(),
                                              ),
                                      ),
                                      Positioned(
                                        top: 10,
                                        right: 10,
                                        child: InkWell(
                                          onTap: controller.removeLogo,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.error(context),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: controller.selectLogo,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: AppColors.primaryAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Icon(Icons.file_upload_outlined,
                              color: AppColors.primaryAccent, size: 20),
                          label: Text(
                            'Upload brand logo',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: fieldGap),

              // 2) Company + Phone (responsive: stacked on phone, 2-col on desktop)
              if (isPhone) ...[
                label('Company Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.companyNameController,
                  validator: ValidationHelper.validateCompanyName,
                  decoration: deco('Enter your company name'),
                ),
                SizedBox(height: fieldGap),
                label('Phone Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: controller.phoneController,
                  keyboardType: TextInputType.phone,
                  validator: ValidationHelper.validatePhoneNumber,
                  decoration:
                      deco('Enter your phone number', prefixText: '+1 '),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Company Name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: controller.companyNameController,
                            validator: ValidationHelper.validateCompanyName,
                            decoration: deco('Enter your company name'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          label('Phone Number'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: controller.phoneController,
                            keyboardType: TextInputType.phone,
                            validator: ValidationHelper.validatePhoneNumber,
                            decoration: deco('Enter your phone number',
                                prefixText: '+1 '),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: fieldGap),

              // 3) Website (optional)
              label(
                'Website',
                trailing: Text(
                  '(Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.websiteController,
                keyboardType: TextInputType.url,
                validator: ValidationHelper.validateOptionalWebsite,
                decoration: deco('Enter your website URL'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _fallbackLogoBox() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[100],
      ),
      child: Center(
        child: Icon(
          Icons.image,
          size: 50,
          color: Colors.grey[600],
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
