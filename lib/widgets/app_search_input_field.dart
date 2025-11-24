import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traxx_wepapp/theme/app_colors.dart';

/// Standardized search input field widget for the Traxx application
///
/// Features:
/// - Search icon with customizable placeholder text
/// - Icon color: black, text color: AppTextMuted
/// - Border states: default (borderInput), hover (borderHover), focus (primaryAccent)
/// - Similar structure to AppTextInputField but optimized for search
class AppSearchInputField extends StatefulWidget {
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
  final String? suffixText;
  final bool filled;
  final Color? fillColor;
  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? focusedBorder;
  final InputBorder? errorBorder;
  final InputBorder? focusedErrorBorder;
  final InputBorder? disabledBorder;
  final double? width;
  final double? height;
  final VoidCallback? onSearchTap;

  const AppSearchInputField({
    super.key,
    this.hintText = 'Search...',
    this.helperText,
    this.errorText,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.keyboardType,
    this.textInputAction = TextInputAction.search,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
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
    this.suffixText,
    this.filled = true,
    this.fillColor,
    this.border,
    this.enabledBorder,
    this.focusedBorder,
    this.errorBorder,
    this.focusedErrorBorder,
    this.disabledBorder,
    this.width,
    this.height,
    this.onSearchTap,
  });

  @override
  State<AppSearchInputField> createState() => _AppSearchInputFieldState();
}

class _AppSearchInputFieldState extends State<AppSearchInputField> {
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
        minHeight: widget.height ?? 44.0, // No label, so shorter height
      ),
      child: MouseRegion(
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
            hintStyle: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16.0,
            ),
            helperText: widget.helperText,
            errorText: widget.errorText,
            prefixIcon: GestureDetector(
              onTap: widget.onSearchTap,
              child: Icon(
                Icons.search,
                color: Colors.black,
                size: 20.0,
              ),
            ),
            suffixIcon: widget.suffixIcon,
            suffixText: widget.suffixText,
            filled: widget.filled,
            fillColor: widget.fillColor ?? AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 10.0,
            ),
            border: widget.border ?? _buildBorder(),
            enabledBorder: widget.enabledBorder ?? _buildBorder(),
            focusedBorder: widget.focusedBorder ?? _buildBorder(),
            errorBorder: widget.errorBorder ?? _buildBorder(),
            focusedErrorBorder: widget.focusedErrorBorder ?? _buildBorder(),
            disabledBorder: widget.disabledBorder ?? _buildBorder(),
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _buildBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8.0),
      borderSide: BorderSide(
        color: _getBorderColor(),
        width: 1.0,
      ),
    );
  }
}
