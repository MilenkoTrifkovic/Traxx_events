
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/constantsOld.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';

AppBar appBar(
  String title,
  String welcome,
  BuildContext context, {
  TextEditingController? textField,
  Color? color,
  Function? profilePress,
  Function? logout,
}) {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
    automaticallyImplyLeading: false,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  pushAndRemoveAllRoute(AppRoute.welcome, context);
                },
                child: Image.asset(
                  color: Theme.of(context).colorScheme.onPrimary,
                  ConstantsOld.lightLogo,
                  height: 40,
                ),
              ),
            ],
          ),
        ),
        Expanded(
            flex: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText.styledHeadingLarge(context, title,
                    color: Theme.of(context).colorScheme.onPrimary),
              ],
            )),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                child: Column(
                  mainAxisAlignment: textField == null
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        AppText.styledHeadingSmall(context, welcome,
                            color: Theme.of(context).colorScheme.onPrimary),
                        AppSpacing.horizontalXs(context),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    pushAndRemoveAllRoute(AppRoute.welcome, context);
                  },
                  icon: Icon(Icons.logout)) //Will be opening dropdown menu
            ],
          ),
        )
      ],
    ),
  );
}
