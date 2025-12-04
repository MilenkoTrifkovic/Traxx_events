import 'package:flutter/material.dart';
import 'package:traxx_wepapp/forms/create_event/event_form_state.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/additional_description_shower.dart';
import 'package:traxx_wepapp/utils/enums/event_type.dart';
import 'package:traxx_wepapp/utils/styled_buttons/styled_icon_button.dart';

class EventServiceRadioButtons extends StatefulWidget {
  final EventFormState formState;

  const EventServiceRadioButtons({super.key, required this.formState});

  @override
  State<EventServiceRadioButtons> createState() =>
      _EventServiceRadioButtonsState();
}

class _EventServiceRadioButtonsState extends State<EventServiceRadioButtons> {
  ServiceType? _selectedServiceType;
  @override
  void initState() {
    if (widget.formState.serviceType != null) {
      _selectedServiceType = widget.formState.serviceType;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<ServiceType> serviceTypes = ServiceType.values;
    List<String> serviceTypeDescriptons =
        ServiceType.values.map((e) => e.description).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.styledBodyMedium(context, 'Select Service Type *'),
        AppSpacing.verticalXs(context),
        Row(
          children: [
            ...serviceTypes.map((serviceType) {
              return ChoiceChip(
                  label: Row(
                    children: [
                      AppText.styledBodyMedium(context, serviceType.name),
                    ],
                  ),
                  onSelected: (value) {
                    setState(() {
                      _selectedServiceType = serviceType;
                      widget.formState.serviceType = serviceType;
                      print(
                          'Selected service type: ${widget.formState.serviceType}');
                    });
                  },
                  selected: _selectedServiceType == serviceType);
            }),
            StyledIconButton(
                icon: Icons.info_outline,
                onPressed: () {
                  AdditionalDescriptionShower.showMessage(
                    context,
                    'Service Types',
                    serviceTypeDescriptons,
                  );
                })
          ],
        ),
      ],
    );
  }
}
