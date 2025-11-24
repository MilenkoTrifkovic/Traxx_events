import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';
import 'package:traxx_wepapp/utils/enums/date_time_input_type.dart';

/// Standardized date/time input field widget for the Traxx application
///
/// Features:
/// - Width: 172px, height: 68px (20px label + 44px input + 4px spacing)
/// - Label height: 20px with semibold body medium text
/// - Input field height: 44px
/// - Border states: default (borderInput), hover (borderHover), focus (primaryAccent), error (inputError)
/// - Supports DateTime, Date only, or Time only selection
/// - Appropriate icons based on selection type
class AppDateTimeInputField extends StatefulWidget {
  final String label;
  final DateTimeInputType inputType;
  final DateTime? selectedDateTime;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final ValueChanged<DateTime?>? onChanged;
  final FormFieldValidator<DateTime>? validator;
  final bool enabled;
  final Color? labelColor;
  final double? width;
  final double? height;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final TimeOfDay? initialTime;

  const AppDateTimeInputField({
    super.key,
    required this.label,
    required this.inputType,
    this.selectedDateTime,
    this.hintText,
    this.helperText,
    this.errorText,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.labelColor,
    this.width,
    this.height,
    this.firstDate,
    this.lastDate,
    this.initialTime,
  });

  @override
  State<AppDateTimeInputField> createState() => _AppDateTimeInputFieldState();
}

class _AppDateTimeInputFieldState extends State<AppDateTimeInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  Color _getBorderColor() {
    if (widget.errorText != null) {
      return AppColors.inputError;
    }
    if (_isFocused) {
      return AppColors.primaryAccent;
    }
    if (_isHovered) {
      return AppColors.borderHover;
    }
    return AppColors.borderInput;
  }

  String _formatDateTime(DateTime dateTime) {
    switch (widget.inputType) {
      case DateTimeInputType.dateTime:
        return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
      case DateTimeInputType.dateOnly:
        return DateFormat('MMM dd, yyyy').format(dateTime);
      case DateTimeInputType.timeOnly:
        return DateFormat('HH:mm').format(dateTime);
    }
  }

  Future<void> _selectDateTime() async {
    if (!widget.enabled) return;

    DateTime? selectedDate = widget.selectedDateTime ?? DateTime.now();
    TimeOfDay? selectedTime = widget.selectedDateTime != null
        ? TimeOfDay.fromDateTime(widget.selectedDateTime!)
        : widget.initialTime ?? TimeOfDay.now();

    switch (widget.inputType) {
      case DateTimeInputType.dateTime:
        // First select date
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: widget.firstDate ?? DateTime(2000),
          lastDate: widget.lastDate ?? DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.primaryAccent,
                    ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          // Then select time
          final TimeOfDay? pickedTime = await showTimePicker(
            context: context,
            initialTime: selectedTime,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: AppColors.primaryAccent,
                      ),
                ),
                child: child!,
              );
            },
          );

          if (pickedTime != null) {
            final finalDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              pickedTime.hour,
              pickedTime.minute,
            );
            widget.onChanged?.call(finalDateTime);
          }
        }
        break;

      case DateTimeInputType.dateOnly:
        final DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: widget.firstDate ?? DateTime(2000),
          lastDate: widget.lastDate ?? DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.primaryAccent,
                    ),
              ),
              child: child!,
            );
          },
        );

        if (pickedDate != null) {
          widget.onChanged?.call(pickedDate);
        }
        break;

      case DateTimeInputType.timeOnly:
        final TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: selectedTime,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.primaryAccent,
                    ),
              ),
              child: child!,
            );
          },
        );

        if (pickedTime != null) {
          final now = DateTime.now();
          final finalDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          widget.onChanged?.call(finalDateTime);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: widget.width ?? 172.0,
        minHeight: widget.height ?? 68.0,
      ),
      margin: EdgeInsets.only(bottom: AppSpacing.xxxs(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          SizedBox(
            height: 20.0,
            child: AppText.styledBodyMedium(
              context,
              widget.label,
              weight: AppFontWeight.semiBold,
              color: widget.labelColor ?? AppColors.primary,
            ),
          ),
          const SizedBox(height: 4.0),
          // Input field
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: FormField<DateTime>(
              validator: widget.validator,
              initialValue: widget.selectedDateTime,
              builder: (FormFieldState<DateTime> field) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _selectDateTime,
                      child: Container(
                        height: 44.0,
                        decoration: BoxDecoration(
                          color: widget.enabled
                              ? AppColors.white
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: field.hasError
                                ? AppColors.inputError
                                : _getBorderColor(),
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 10.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.selectedDateTime != null
                                      ? _formatDateTime(
                                          widget.selectedDateTime!)
                                      : widget.hintText ??
                                          widget.inputType.hintText,
                                  style: TextStyle(
                                    color: widget.selectedDateTime != null
                                        ? Colors.black87
                                        : Colors.grey[500],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: SvgPicture.asset(
                                  widget.inputType.iconPath,
                                  colorFilter: ColorFilter.mode(
                                    widget.enabled
                                        ? AppColors.textMuted
                                        : Colors.grey[400]!,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Error text
                    if (field.hasError) ...[
                      const SizedBox(height: 4),
                      Text(
                        field.errorText!,
                        style: TextStyle(
                          color: AppColors.inputError,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    // Helper text
                    if (widget.helperText != null && !field.hasError) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.helperText!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
