import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';
import 'package:traxx_wepapp/theme/app_font_weight.dart';
import 'package:traxx_wepapp/theme/styled_app_text.dart';

/// Standardized text input field widget for the Traxx application
///
/// Features:
/// - Maximum width: 360px, height: 68px (20px label + 44px input + 4px spacing)
/// - Label height: 20px with semibold body medium text
/// - Input field height: 44px
/// - Border states: default (borderInput), hover (borderHover), focus (primaryAccent), error (inputError)
class AppTextInputField extends StatefulWidget {
  final String label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final TextStyle? style;
  final TextAlign textAlign;
  final bool autofocus;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final bool readOnly;
  final bool? showCursor;
  final int? maxLength;
  final MaxLengthEnforcement? maxLengthEnforcement;
  final ValueChanged<String>? onChanged;
  final GestureTapCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? prefixText;
  final String? suffixText;
  final bool filled;
  final Color? fillColor;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final InputBorder? disabledBorder;
  final Color? labelColor;
  final double? width;
  final double? height;

  const AppTextInputField({
    super.key,
    required this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.readOnly = false,
    this.showCursor,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onTap,
    this.onTapOutside,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.onSaved,
    this.validator,
    this.inputFormatters,
    this.enabled,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.suffixIcon,
    this.prefixIcon,
    this.prefixText,
    this.suffixText,
    this.filled = true,
    this.fillColor,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.disabledBorder,
    this.labelColor,
    this.width,
    this.height,
  });

  @override
  State<AppTextInputField> createState() => _AppTextInputFieldState();
}

class _AppTextInputFieldState extends State<AppTextInputField> {
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
          // Input field - Remove fixed height to allow for error text expansion
          MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: TextFormField(
              controller: widget.controller,
              initialValue: widget.initialValue,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              style: widget.style,
              textAlign: widget.textAlign,
              autofocus: widget.autofocus,
              obscureText: widget.obscureText,
              autocorrect: widget.autocorrect,
              enableSuggestions: widget.enableSuggestions,
              maxLines: widget.maxLines,
              minLines: widget.minLines,
              expands: widget.expands,
              readOnly: widget.readOnly,
              showCursor: widget.showCursor,
              maxLength: widget.maxLength,
              maxLengthEnforcement: widget.maxLengthEnforcement,
              onChanged: widget.onChanged,
              onTap: widget.onTap,
              onTapOutside: widget.onTapOutside,
              onEditingComplete: widget.onEditingComplete,
              onFieldSubmitted: widget.onFieldSubmitted,
              onSaved: widget.onSaved,
              validator: widget.validator,
              inputFormatters: widget.inputFormatters,
              enabled: widget.enabled,
              scrollPadding: widget.scrollPadding,
              enableInteractiveSelection: widget.enableInteractiveSelection,
              decoration: InputDecoration(
                hintText: widget.hintText,
                helperText: widget.helperText,
                errorText: widget.errorText,
                suffixIcon: widget.suffixIcon,
                prefixIcon: widget.prefixIcon,
                prefixText: widget.prefixText,
                suffixText: widget.suffixText,
                filled: widget.filled,
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
                // Override the border based on current state
                // This ensures hover state works properly
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
