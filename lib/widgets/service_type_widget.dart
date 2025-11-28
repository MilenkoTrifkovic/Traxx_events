import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:traxx_wepapp/utils/enums/event_type.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

class ServiceTypeWidget extends StatelessWidget {
  final ServiceType serviceType;
  const ServiceTypeWidget({super.key, required this.serviceType});

  Color get backgroundColor {
    switch (serviceType) {
      case ServiceType.buffet:
        return const Color(0xFFF3F4F6); // light gray
      case ServiceType.plated:
        return const Color(0xFFE0F7FA); // light blue
    }
  }

  Color get textColor {
    switch (serviceType) {
      case ServiceType.buffet:
        return const Color(0xFF6B7280); // gray
      case ServiceType.plated:
        return const Color(0xFF2563EB); // blue
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: AppText.styledMetaSmall(
        context,
        serviceType.name.toString().capitalize!,
        color: textColor,
        weight: FontWeight.w600,
      ),
    );
  }
}
