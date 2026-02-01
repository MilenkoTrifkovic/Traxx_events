import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/constantsOld.dart';
import 'package:traxx_wepapp/widgets/welcome_app_bar.dart';

class ContactView extends StatelessWidget {
  const ContactView({super.key});

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
                AppText.styledHeadingLarge(context, 'CONTACT'),
                AppSpacing.verticalMd(context),
              ],
            ),
          ),
          Expanded(
              flex: 3,
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  color: AppColors.primaryOld(context),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          AppSpacing.verticalMd(context),
                          AppSpacing.verticalMd(context),
                          AppText.styledBodyLarge(context,
                              'If you wish to get in touch with us about general inqueries or events,\nplease use the email address provided below',
                              weight: FontWeight.bold,
                              color: AppColors.onPrimary(context),
                              textAlign: TextAlign.center),
                          AppSpacing.verticalMd(context),
                          AppSpacing.verticalMd(context),
                          AppText.styledBodyMedium(context, ConstantsOld.email,
                              color: AppColors.onPrimary(context),
                              weight: FontWeight.bold),
                          AppSpacing.verticalMd(context),
                          AppSpacing.verticalMd(context),
                          AppText.styledBodyMedium(context, 'Our hours are',
                              color: AppColors.onPrimary(context),
                              weight: FontWeight.bold),
                          AppText.styledBodyMedium(context, ConstantsOld.timing,
                              color: AppColors.onPrimary(context)),
                          AppSpacing.verticalMd(context),
                          AppText.styledBodyMedium(
                              context, ConstantsOld.location,
                              color: AppColors.onPrimary(context)),
                          AppSpacing.verticalMd(context),
                          AppSpacing.verticalMd(context),
                          AppText.styledBodyLarge(context,
                              "For further assistance with Trax Event,\nplease use the chat feature by clicking on the chat icon in the right bottom of this screen",
                              weight: FontWeight.bold,
                              color: AppColors.onPrimary(context),
                              textAlign: TextAlign.center),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppText.styledBodySmall(
                            context, ConstantsOld.trademark,
                            color: AppColors.onPrimary(context),
                            weight: FontWeight.normal),
                      ),
                    ],
                  ))),
        ],
      ),
    );
  }
}
