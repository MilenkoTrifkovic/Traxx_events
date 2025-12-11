import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/features/settings/controllers/settings_screen_controller.dart';
import 'package:traxx_wepapp/widgets/image_picker.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';

/// Left-hand profile photo area used on the Settings page.
/// Shows the photo picker and a small spacer below it.
class ProfilePhotoSection extends StatelessWidget {
  final SettingsScreenController controller;

  const ProfilePhotoSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Obx(() {
          return ReusablePhotoPicker(
            imageUrl: controller.currentImageUrl.value,
            displayButton: true,
            maxWidth: 300,
            onPick: () {
              controller.pickAndUploadImage();
              return null;
            },
          );
        }),
        AppSpacing.verticalSm(context),
      ],
    );
  }
}
