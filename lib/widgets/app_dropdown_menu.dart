import 'package:flutter/material.dart';
import 'package:traxx_wepapp/helper/app_spacing.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

/// Standardized dropdown menu widget for the Traxx application
///
/// Features:
/// - Maximum width: 360px, height: 68px (20px label + 44px dropdown + 4px spacing)
/// - Label height: 20px with semibold body medium text
/// - Dropdown field height: 44px
/// - Border states: default (borderInput), hover (borderHover), focus (primaryAccent), error (inputError)
class AppDropdownMenu<T> extends StatefulWidget {
  final String label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool? enabled;
  final Widget? icon;
  final double? iconSize;
  final Color? iconDisabledColor;
  final Color? iconEnabledColor;
  final double? itemHeight;
  final bool isDense;
  final bool isExpanded;
  final double? menuMaxHeight;
  final VoidCallback? onTap;
  final Color? labelColor;
  final double? width;
  final double? height;
  final Color? fillColor;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final InputBorder? disabledBorder;

  const AppDropdownMenu({
    super.key,
    required this.label,
    required this.items,
    this.hintText,
    this.helperText,
    this.errorText,
    this.value,
    this.onChanged,
    this.validator,
    this.focusNode,
    this.autofocus = false,
    this.enabled,
    this.icon,
    this.iconSize = 24.0,
    this.iconDisabledColor,
    this.iconEnabledColor,
    this.itemHeight = kMinInteractiveDimension,
    this.isDense = true,
    this.isExpanded = true,
    this.menuMaxHeight,
    this.onTap,
    this.labelColor,
    this.width,
    this.height,
    this.fillColor,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.disabledBorder,
  });

  @override
  State<AppDropdownMenu<T>> createState() => _AppDropdownMenuState<T>();
}

class _AppDropdownMenuState<T> extends State<AppDropdownMenu<T>> {
  late FocusNode _focusNode;
  bool _isHovered = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: widget.width ?? 360.0,
        // Remove fixed maxHeight to allow for validation errors
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
          // Dropdown field - Remove fixed height to allow for error text expansion
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: DropdownButtonFormField<T>(
              initialValue: widget.value,
              items: widget.items,
              // Respect the enabled flag: when disabled, onChanged must be null
              onChanged: widget.enabled == false ? null : widget.onChanged,
              validator: widget.validator,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              icon: widget.icon,
              iconSize: widget.iconSize ?? 24.0,
              iconDisabledColor: widget.iconDisabledColor,
              iconEnabledColor: widget.iconEnabledColor,
              itemHeight: widget.itemHeight,
              isDense: widget.isDense,
              isExpanded: widget.isExpanded,
              menuMaxHeight: widget.menuMaxHeight,
              onTap: widget.onTap,
              decoration: InputDecoration(
                hintText: widget.hintText,
                helperText: widget.helperText,
                errorText: widget.errorText,
                filled: true,
                fillColor: widget.fillColor ?? AppColors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 10.0,
                ),
                border: widget.border ?? _buildBorder(AppColors.borderInput),
                enabledBorder:
                    widget.enabledBorder ?? _buildBorder(AppColors.borderInput),
                focusedBorder: widget.focusedBorder ??
                    _buildBorder(AppColors.primaryAccent),
                errorBorder:
                    widget.errorBorder ?? _buildBorder(AppColors.inputError),
                focusedErrorBorder: widget.focusedErrorBorder ??
                    _buildBorder(AppColors.inputError),
                disabledBorder: widget.disabledBorder ??
                    _buildBorder(AppColors.borderInput),
              ),
            ),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(
        color: _getBorderColor(),
        width: 1.0,
      ),
    );
  }
}
