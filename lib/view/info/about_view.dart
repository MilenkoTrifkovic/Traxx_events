import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/widgets/welcome_app_bar.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: welcomeAppBar(context),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppText.styledHeadingLarge(context, 'ABOUT US',
                    color: AppColors.primary(context)),
                AppSpacing.verticalMd(context),
              ],
            ),
          ),
          Expanded(
              flex: 3,
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  color: AppColors.primary(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText.styledBodyMedium(
                        context,
                        "Traxx Events got started in Wilmington New York at the Hungry Trout Restaurant.\n\n\nWhile busy managing normal every day goings on around the restaurant and resort, the team\nrealized that there was something missing.\n\n\nThe guests attending an event hosted there were often in the dark about what food would be\nprovided and on top of that, if they could eat it,\ndue to dietary restrictions.\n\n\nThat's when Traxx was born",
                        weight: FontWeight.w500,
                        color: AppColors.onPrimary(context),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ))),
        ],
      ),
    );
  }
}
