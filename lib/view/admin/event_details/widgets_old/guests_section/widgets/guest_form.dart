// TODO: Consider separating UI and logic later for cleaner structure.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:traxx_wepapp/controller/admin_controllers/guests_controllers/set_guests_controller.dart';
import 'package:traxx_wepapp/exeptions/exeptions.dart';
import 'package:traxx_wepapp/helper/app_decoration.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/validation.dart';
import 'package:traxx_wepapp/theme/constants.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';
import 'package:traxx_wepapp/utils/snackbar_utils.dart';
import 'package:traxx_wepapp/utils/styled_buttons/styled_text_button.dart';

/// A form widget for adding new guests to the event.
///
/// Provides input fields for email, name, and number of companions.
/// Handles form validation, guest creation, and automatically scrolls
/// to show the newly added guest in the list.
class GuestForm extends StatefulWidget {
  final GlobalKey<AnimatedListState> listKey;
  final ScrollController scrollController;
  final void Function(int index) addColor;

  const GuestForm(
      {super.key,
      required this.listKey,
      required this.scrollController,
      required this.addColor});

  @override
  State<GuestForm> createState() => _GuestFormState();
}

class _GuestFormState extends State<GuestForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  late final TextEditingController emailController;
  late final TextEditingController nameController;
  late final TextEditingController companionsController;

  // Focus nodes
  late final FocusNode emailFocus;
  late final FocusNode nameFocus;
  late final FocusNode companionsFocus;

  int companions = 0;

  final SetGuestsController setGuestsController =
      Get.find<SetGuestsController>();

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    emailController = TextEditingController();
    nameController = TextEditingController();
    companionsController = TextEditingController();

    // Initialize focus nodes
    emailFocus = FocusNode();
    nameFocus = FocusNode();
    companionsFocus = FocusNode();
  }

  @override
  void dispose() {
    // Dispose controllers
    emailController.dispose();
    nameController.dispose();
    companionsController.dispose();

    // Dispose focus nodes
    emailFocus.dispose();
    nameFocus.dispose();
    companionsFocus.dispose();

    super.dispose();
  }

  String? _fieldValidation(String message, String? value) {
    if (value == null || value.isEmpty) {
      return message;
    }
    return null;
  }

  void _resetForm() {
    emailController.clear();
    nameController.clear();
    companionsController.clear();
    if (mounted) setState(() {});
  }

  void _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final companions = int.tryParse(companionsController.text);
    if (companions == null) {
      SnackBarUtils.showError(context, 'Please enter a valid number');
      return;
    }
    try {
      final index = await setGuestsController.addGuest(
          emailController.text.trim(), nameController.text.trim(), companions);
      widget.addColor(index);
      widget.listKey.currentState?.insertItem(index);

      // Reset form after successful addition
      _resetForm();

      // Wait for the list animation to start before scrolling
      await Future.delayed(Duration(milliseconds: 300));
      if (mounted) {
        await widget.scrollController.animateTo(
          Constants.guestListContainerHeight * index,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOutCirc,
        );
      }
    } on EmailInUseException catch (e) {
      SnackBarUtils.showError(context, e.message);
    } on GuestLimitExceededException catch (e) {
      SnackBarUtils.showError(context, e.message);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      SnackBarUtils.showError(context, msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        decoration: AppDecorations.formContainer(context),
        child: Column(children: [
          Padding(
            padding: AppPadding.horizontal(context, paddingType: Sizes.xs),
            child: Row(
              children: [
                Expanded(
                  child: FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        //Email
                        TextFormField(
                          controller: emailController,
                          focusNode: emailFocus,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter guest\'s email',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).requestFocus(nameFocus);
                          },
                          validator: Validation.validateEmail,
                        ),
                        AppSpacing.verticalXs(context),
                        //Name
                        TextFormField(
                          controller: nameController,
                          focusNode: nameFocus,
                          decoration: InputDecoration(
                            labelText: 'Name',
                            hintText: 'Enter guest\'s name',
                          ),
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context)
                                .requestFocus(companionsFocus);
                          },
                          validator: (value) =>
                              _fieldValidation('Please enter a name', value),
                        ),
                        AppSpacing.verticalXs(context),
                        //Companions
                        TextFormField(
                          controller: companionsController,
                          focusNode: companionsFocus,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            labelText: 'Companions',
                            hintText: 'Number of additional guests',
                          ),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            _onSubmit();
                          },
                          validator: (value) =>
                              _fieldValidation('Please enter a number', value),
                        ),
                        AppSpacing.verticalXs(context),
                        //Submit button
                        StyledTextIconButton(
                            onPressed: _onSubmit,
                            text: 'Add Guest',
                            icon: Icon(
                              Icons.add,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
