import 'package:flutter/material.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

class SelectedMenuItemRow extends StatelessWidget {
  final MenuItem menuItem;
  final double imageSize;
  final VoidCallback? onRemove;

  const SelectedMenuItemRow({
    super.key,
    required this.menuItem,
    required this.onRemove,
    this.imageSize = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: _buildImage(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              AppText.styledBodyMedium(
                context,
                menuItem.name,
                weight: AppFontWeight.semiBold,
              ),
              if ((menuItem.description ?? '').isNotEmpty)
                AppText.styledMetaSmall(
                  context,
                  color: AppColors.black,
                  menuItem.description!,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        Column(
          children: [
            SizedBox(
              child: TextButton(
                  onPressed: onRemove,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.black,
                  )),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildImage() {
    final String? url = menuItem.imageUrl;
    if (url == null || url.isEmpty) {
      return Container(
        width: imageSize,
        height: imageSize,
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.broken_image,
          size: 20,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      url,
      width: imageSize,
      height: imageSize,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => Container(
        width: imageSize,
        height: imageSize,
        color: Colors.grey.shade200,
        child: const Icon(
          Icons.broken_image,
          size: 20,
          color: Colors.grey,
        ),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: imageSize,
          height: imageSize,
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 20,
              color: Colors.grey,
            ),
          ),
        );
      },
    );
  }
}
