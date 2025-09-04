import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/host_controllers/menu_controllers/set_menus_controller.dart';
import 'package:traxx_wepapp/helper/app_border_radius.dart';
import 'package:traxx_wepapp/models/menu.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/loader.dart';

class UploadMenuPhoto extends StatefulWidget {
  final double size;
  final MenuItem menuItem;

  const UploadMenuPhoto({
    super.key,
    required this.size,
    required this.menuItem,
  });

  @override
  State<UploadMenuPhoto> createState() => _UploadMenuPhotoState();
}

class _UploadMenuPhotoState extends State<UploadMenuPhoto> {
  final Widget placeholder =
      const Icon(Icons.add_a_photo, size: 32, color: Colors.grey);
  SetMenusController setMenusController = Get.find<SetMenusController>();

  Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          showLoadingIndicator(status: 'Please upload a photo');
          XFile? menuImage =
              await setMenusController.loadMenuImage(menuItem: widget.menuItem);
          bytes = await menuImage!.readAsBytes();
          setState(() {});
        } catch (e) {
          print("Error picking image: $e");
        } finally {
          hideLoadingIndicator();
        }
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          borderRadius: AppBorderRadius.radius(context, size: Sizes.sm),
          border: Border.all(color: AppColors.onPrimary(context)),
          color: Colors.grey[200],
        ),
        child: showPlaceholder()
            ? placeholder
            : Container(
                decoration: BoxDecoration(
                  borderRadius: AppBorderRadius.radius(context, size: Sizes.sm),
                  image: DecorationImage(
                    image: _getImage(),
                    // : Image.network(menuImage!.path).image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
      ),
    );
  }

  bool showPlaceholder() {
    return bytes == null && widget.menuItem.imageUrl == null;
  }

  ImageProvider _getImage() {
    if (bytes != null) return MemoryImage(bytes!);
    if (widget.menuItem.imageUrl != null) {
      return NetworkImage(widget.menuItem.imageUrl!);
    }
    // Return a default empty image provider if needed, but your placeholder logic should prevent this.
    return MemoryImage(Uint8List(0));
  }
}
