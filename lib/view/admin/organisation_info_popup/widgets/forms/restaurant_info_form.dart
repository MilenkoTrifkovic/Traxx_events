import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
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
          const SizedBox(height: 32),

          // Only NEW restaurant form – existing restaurant logic removed
          _NewRestaurantForm(controller: controller),
        ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Brand Logo Upload
        SizedBox(
          width: 230,
          height: 180,
          child: Column(
            children: [
              Expanded(
                child: Obx(
                  () => Container(
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
                                          return _fallbackLogoBox();
                                        },
                                      )
                                    : Image.file(
                                        File(
                                          controller.selectedImagePath.value!,
                                        ),
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return _fallbackLogoBox();
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
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Company Name',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
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
        const SizedBox(height: 24),

        // 3. Phone Number
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Phone Number',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
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
        const SizedBox(height: 24),

        // 4. Website (Optional)
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
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

/* /// NEW: selector for existing restaurants
class _ExistingRestaurantSelector extends StatelessWidget {
  final OrganisationInfoController controller;

  const _ExistingRestaurantSelector({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingExistingOrganisations.value) {
        return const SizedBox(
          height: 120,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      final orgs = controller.existingOrganisations;
      if (orgs.isEmpty) {
        return const Padding(
          padding: EdgeInsets.only(top: 16.0),
          child: Text(
            'No restaurants found yet. Please create a new one.',
            style: TextStyle(color: Colors.black54),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Select a restaurant',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(height: 12),
          ...orgs.map((org) {
            return RadioListTile<String>(
              value: org.id,
              groupValue: controller.selectedExistingOrganisationId.value,
              onChanged: (val) {
                if (val != null) {
                  controller.selectExistingOrganisation(val);
                }
              },
              title: Text(org.name),
              subtitle: org.city.isNotEmpty ? Text(org.city) : const SizedBox(),
            );
          }).toList(),
        ],
      );
    });
  }
}

/// Original "new restaurant" form extracted into its own widget
class _NewRestaurantForm extends StatelessWidget {
  final OrganisationInfoController controller;

  const _NewRestaurantForm({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Brand Logo Upload
        SizedBox(
          width: 230,
          height: 180,
          child: Column(
            children: [
              Expanded(
                child: Obx(
                  () => Container(
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
                                          return _fallbackLogoBox();
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
                                          return _fallbackLogoBox();
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
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Company Name',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
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
        const SizedBox(height: 24),

        // 3. Phone Number
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Phone Number',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
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
        const SizedBox(height: 24),

        // 4. Website (Optional)
        Align(
          alignment: Alignment.centerLeft,
          child: Row(
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
 */
