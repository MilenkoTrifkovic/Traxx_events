import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/auth_controller/auth_controller.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/utils/enums/user_type.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/extensions/string_extensions.dart';
import 'package:traxx_wepapp/utils/navigation/app_routes.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/utils/navigation/routes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';

import '../../../widgets/welcome_app_bar.dart';

/// The welcome screen of the application.
/// Provides login functionality with role selection (host/planner).
class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  late AuthController authController;

  /// Form key for validation
  final _formKey = GlobalKey<FormState>();

  /// Controller for email input
  final _emailController = TextEditingController();

  /// Controller for password input
  final _passwordController = TextEditingController();

  /// Focus node for password field
  final _passwordFocusNode = FocusNode();

  /// Selected user role, defaults to guest
  UserType _selectedRole = UserType.guest;
  @override
  void initState() {
    authController = Get.find<AuthController>();
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Validates email format using regex
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Handles the login action based on selected role
  void _handleLogin(BuildContext context) {
    // if (_formKey.currentState!.validate()) {//Commented for testing purposes
    if (_selectedRole == UserType.host) {
      authController.setUserType(UserType.host);
      pushAndRemoveAllRoute(AppRoute.hostEvents, context);
    } else if (_selectedRole == UserType.guest) {
      authController.setUserType(UserType.guest);
      pushAndRemoveAllRoute(AppRoute.guestEvents, context);
    } else {
      SnackBarUtils.showInfo(context, 'Currently only host login is available');
    }
    // }
  }

  /// Builds the welcome screen with login form and role selection
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: welcomeAppBar(context),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Expanded(
              flex: 1,
              child: Padding(
                padding: AppPadding.all(context, paddingType: Sizes.md),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppText.styledHeadingLarge(
                          context, 'MAKING AN EVENT OUT OF KEEPING TRACK'),
                      AppSpacing.verticalMd(context),
                      AppText.styledBodySmall(
                          context, 'Login to access your account')
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                width: MediaQuery.of(context).size.width,
                color: Theme.of(context).colorScheme.primary,
                child: Center(
                  child: SingleChildScrollView(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: 500,
                        minWidth: 0,
                      ),
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            //Email
                            TextFormField(
                              controller: _emailController,
                              textInputAction: TextInputAction.next,
                              style: TextStyle(
                                  color: AppColors.onPrimary(context)),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(
                                    color: AppColors.onPrimary(context)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.onPrimary(context)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.onPrimary(context)),
                                ),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter email';
                                }
                                if (!isValidEmail(value!)) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                _passwordFocusNode.requestFocus();
                              },
                            ),
                            AppSpacing.verticalMd(context),
                            //Password
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              textInputAction: TextInputAction.done,
                              obscureText: true,
                              style: TextStyle(
                                  color: AppColors.onPrimary(context)),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                    color: AppColors.onPrimary(context)),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.onPrimary(context)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: AppColors.onPrimary(context)),
                                ),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter password';
                                }
                                if (value!.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) {
                                _handleLogin(context);
                              },
                            ),
                            AppSpacing.verticalMd(context),
                            // Role selection
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildRoleOption(UserType.planner,
                                    'assets/icons/clipboard-solid.svg'),
                                _buildRoleOption(UserType.host,
                                    'assets/icons/user-tie-solid.svg'),
                                _buildRoleOption(UserType.guest,
                                    'assets/icons/users-solid.svg'),
                              ],
                            ),
                            AppSpacing.verticalMd(context),
                            // Login button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _handleLogin(context),
                                child:
                                    AppText.styledBodyMedium(context, 'Login'),
                              ),
                            ),
                            AppSpacing.verticalMd(context),
                            //Register
                            TextButton(
                              onPressed: () {
                                // pushRoute(AppRoute.register, context),
                                pushAndRemoveAllRoute(AppRoute.signup, context);
                              },
                              child: AppText.styledBodySmall(
                                  context, 'New user? Register here',
                                  color: AppColors.onPrimary(context)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption(UserType role, String iconPath) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconPath,
          height: 24,
          colorFilter: ColorFilter.mode(
            AppColors.onPrimary(context),
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(height: 8),
        Radio<UserType>(
          value: role,
          groupValue: _selectedRole,
          onChanged: (UserType? value) {
            setState(() => _selectedRole = value!);
          },
          fillColor: WidgetStateProperty.all(AppColors.onPrimary(context)),
        ),
        AppText.styledBodyLarge(context, role.name.capitalizeString(),
            color: AppColors.onPrimary(context)),
      ],
    );
  }
}
