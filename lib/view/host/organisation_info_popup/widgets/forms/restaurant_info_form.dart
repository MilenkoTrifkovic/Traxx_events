import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/loader.dart';
import 'package:traxx_wepapp/view/host/organisation_info_popup/widgets/section_header.dart';
import 'package:traxx_wepapp/helper/validation_helper.dart';
import 'package:traxx_wepapp/utils/organisation_form_keys.dart';
import 'package:traxx_wepapp/controller/host_controllers/organisation_info_controller.dart';

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
    return Form(
      key: OrganisationFormKeys.restaurantInfoFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SectionHeader(
            icon: Icons.restaurant,
            title: 'Restaurant Info',
            description: 'Provide basic information about your restaurant.',
          ),
          const SizedBox(height: 40),

          // 1. Brand Logo Upload
          SizedBox(
            width: 230,
            height: 180,
            child: Column(
              children: [
                // Image display area
                Expanded(
                  child: Obx(() => Container(
                        width: 230,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: controller.selectedImagePath.value == null
                            ? InkWell(
                                onTap: controller.selectLogo,
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: Icon(
                                    Icons.photo_library_outlined,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              )
                            : Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: kIsWeb
                                        ? Image.network(
                                            controller.selectedImagePath.value!,
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: double.infinity,
                                                height: double.infinity,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                            },
                                          )
                                        : Image.file(
                                            File(controller
                                                .selectedImagePath.value!),
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                width: double.infinity,
                                                height: double.infinity,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                            },
                                          ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: InkWell(
                                      onTap: controller.removeLogo,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
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
                      )),
                ),
                const SizedBox(height: 16),
                // Upload button
                SizedBox(
                  width: 230,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: controller.selectLogo,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.white,
                      side: BorderSide(color: AppColors.primaryAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: Icon(
                      Icons.file_upload_outlined,
                      color: AppColors.primaryAccent,
                      size: 24,
                    ),
                    label: AppText.styledBodyMedium(
                      weight: AppFontWeight.semiBold,
                      context,
                      color: AppColors.primaryAccent,
                      'Upload the brand logo',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Company Name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Company Name',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.companyNameController,
                validator: ValidationHelper.validateCompanyName,
                decoration: const InputDecoration(
                  hintText: 'Enter your company name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3. Phone Number
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phone Number',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.phoneController,
                keyboardType: TextInputType.phone,
                validator: ValidationHelper.validatePhoneNumber,
                decoration: const InputDecoration(
                  hintText: 'Enter your phone number',
                  border: OutlineInputBorder(),
                  prefixText: '+1 ',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 4. Website (Optional)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Website',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(Optional)',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: controller.websiteController,
                keyboardType: TextInputType.url,
                validator: ValidationHelper.validateOptionalWebsite,
                decoration: const InputDecoration(
                  hintText: 'Enter your website URL',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
