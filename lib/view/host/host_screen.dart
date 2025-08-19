import 'package:flutter/widgets.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

class HostScreen extends StatelessWidget {
  const HostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppText.styledHeadingMedium(context, "Host Events Screen"),
    );
  }
}
