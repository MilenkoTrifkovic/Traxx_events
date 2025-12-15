import 'package:flutter/material.dart';
import 'package:traxx_wepapp/models/event_questions.dart';
import 'package:traxx_wepapp/controller/admin_controllers/set_questions_controller.dart';
import 'package:traxx_wepapp/helper/app_decoration.dart';
import 'package:traxx_wepapp/helper/app_padding.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/helper/screen_size.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/input_type.dart';
import 'package:traxx_wepapp/utils/enums/sizes.dart';

/// Widget that allows event hosts to create and edit custom fields for guest information.
/// Each field has a name, group ID, and input type (text, number, date, or yes/no).
/// Supports both mobile and desktop layouts.
class GuestInfoFieldWidget extends StatefulWidget {
  final EventQuestions guestFieldConfig;
  final SetQuestionsController guestInfoController;
  final VoidCallback? onDelete;
  const GuestInfoFieldWidget({
    super.key,
    this.onDelete,
    required this.guestFieldConfig,
    required this.guestInfoController,
  });

  @override
  State<GuestInfoFieldWidget> createState() => _GuestInfoFieldWidgetState();
}

class _GuestInfoFieldWidgetState extends State<GuestInfoFieldWidget> {
  InputType? selectedInputType;

  @override
  void initState() {
    selectedInputType = widget.guestFieldConfig.inputType;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: AppDecorations.formContainer(context),
        child: Padding(
            padding: AppPadding.all(context, paddingType: Sizes.sm),
            child: ScreenSize.isPhone(context)
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: buildGuestFieldWidgets(context),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: buildGuestFieldWidgets(context).map((w) {
                      if (w is TextFormField) {
                        return Expanded(flex: 3, child: w);
                      }
                      if (w is DropdownButtonFormField) {
                        return Expanded(flex: 2, child: w);
                      }
                      return w;
                    }).toList(),
                  )));
  }

  List<Widget> buildGuestFieldWidgets(BuildContext context) {
    final isPhone = ScreenSize.isPhone(context);
    return [
      AppText.styledBodyMedium(context, 'Field Name:', weight: FontWeight.bold),
      isPhone
          ? AppSpacing.verticalXs(context)
          : AppSpacing.horizontalMd(context),
      TextFormField(
        controller: widget.guestFieldConfig.fieldNameController,
        decoration: InputDecoration(
          hintText: 'Enter name',
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      isPhone
          ? AppSpacing.verticalMd(context)
          : AppSpacing.horizontalMd(context),
      AppText.styledBodyMedium(context, 'Group ID:', weight: FontWeight.bold),
      isPhone
          ? AppSpacing.verticalXs(context)
          : AppSpacing.horizontalMd(context),
      TextFormField(
        controller: widget.guestFieldConfig.groupIdController,
        decoration: InputDecoration(
          hintText: 'Enter Group ID',
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      isPhone
          ? AppSpacing.verticalMd(context)
          : AppSpacing.horizontalMd(context),
      AppText.styledBodyMedium(context, 'Input Type:', weight: FontWeight.bold),
      isPhone
          ? AppSpacing.verticalXs(context)
          : AppSpacing.horizontalMd(context),
      DropdownButtonFormField<InputType>(
        //Causes overflow problem, because of dropdown items...
        initialValue: selectedInputType,
        onChanged: (value) {
          widget.guestFieldConfig.changeInputType(value!);
        },
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        items: [
          DropdownMenuItem(
              value: InputType.number,
              child: AppText.styledBodyMedium(context, 'Number')),
          DropdownMenuItem(
              value: InputType.date,
              child: AppText.styledBodyMedium(context, 'Date')),
          DropdownMenuItem(
              value: InputType.yesno,
              child: AppText.styledBodyMedium(context, 'Yes/No')),
          DropdownMenuItem(
              value: InputType.text,
              child: AppText.styledBodyMedium(context, 'Text')),
        ],
      ),
      isPhone
          ? AppSpacing.verticalMd(context)
          : AppSpacing.horizontalMd(context),
      IconButton(
        icon: Icon(Icons.delete, color: AppColors.error(context)),
        onPressed: widget.onDelete,
      ),
    ];
  }
}
