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
/// - Optional search functionality for large lists (set enableSearch: true)
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
  final bool enableSearch;
  final String Function(T item)? searchExtractor;

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
    this.enableSearch = false,
    this.searchExtractor,
  });

  @override
  State<AppDropdownMenu<T>> createState() => _AppDropdownMenuState<T>();
}

class _AppDropdownMenuState<T> extends State<AppDropdownMenu<T>> {
  late FocusNode _focusNode;
  bool _isHovered = false;
  bool _isFocused = false;
  
  // Search-related state
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  OverlayEntry? _overlayEntry;
  bool _isOverlayOpen = false;
  List<DropdownMenuItem<T>> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.removeListener(_onFocusChange);
      _focusNode.dispose();
    }
    _closeOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _openOverlay() {
    if (widget.enabled == false) return;
    _overlayEntry = _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOverlayOpen = true);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _searchController.clear();
    _filteredItems = widget.items;
    if (mounted) {
      setState(() => _isOverlayOpen = false);
    }
  }

  void _toggleOverlay() {
    if (_isOverlayOpen) {
      _closeOverlay();
    } else {
      _openOverlay();
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final searchText = widget.searchExtractor != null
              ? widget.searchExtractor!(item.value as T)
              : item.value.toString();
          return searchText.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });

    if (!_isOverlayOpen) _openOverlay();
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlay() {
    RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;

    return OverlayEntry(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeOverlay,
          child: Stack(
            children: [
              Positioned(
                width: size.width,
                child: CompositedTransformFollower(
                  link: _layerLink,
                  offset: Offset(0, 52),
                  showWhenUnlinked: false,
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: widget.menuMaxHeight ?? 260,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.primaryAccent,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search field at the top
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: AppColors.borderInput,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              onChanged: _filterItems,
                              decoration: InputDecoration(
                                hintText: 'Search...',
                                prefixIcon: Icon(
                                  Icons.search,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: AppColors.borderInput,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: AppColors.borderInput,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                  borderSide: BorderSide(
                                    color: AppColors.primaryAccent,
                                  ),
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                              ),
                            ),
                          ),
                          // Results list
                          Flexible(
                            child: _filteredItems.isEmpty
                                ? Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: AppText.styledBodyMedium(
                                      context,
                                      'No results found',
                                      color: AppColors.textMuted,
                                      textAlign: TextAlign.center,
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    itemCount: _filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredItems[index];
                                      final isSelected = item.value == widget.value;

                                      return InkWell(
                                        onTap: () {
                                          widget.onChanged?.call(item.value);
                                          _closeOverlay();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0,
                                            vertical: 10.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? AppColors.primaryAccent
                                                    .withOpacity(0.1)
                                                : null,
                                          ),
                                          child: DefaultTextStyle(
                                            style: TextStyle(
                                              color: isSelected
                                                  ? AppColors.primaryAccent
                                                  : AppColors.primary,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              fontSize: 14,
                                            ),
                                            child: item.child,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getBorderColor() {
    if (widget.errorText != null) {
      return AppColors.inputError;
    }
    if (_isFocused || _isOverlayOpen) {
      return AppColors.primaryAccent;
    }
    if (_isHovered) {
      return AppColors.borderHover;
    }
    return AppColors.borderInput;
  }

  @override
  Widget build(BuildContext context) {
    // If search is enabled, render search field with overlay
    if (widget.enableSearch) {
      return _buildSearchableDropdown();
    }
    
    // Otherwise, render standard dropdown
    return _buildStandardDropdown();
  }

  Widget _buildSearchableDropdown() {
    final displayText = widget.value != null
        ? widget.items
            .firstWhere(
              (item) => item.value == widget.value,
              orElse: () => widget.items.first,
            )
            .child
        : null;

    return Container(
      constraints: BoxConstraints(
        maxWidth: widget.width ?? 360.0,
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
          // Dropdown field with overlay
          CompositedTransformTarget(
            link: _layerLink,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTap: widget.enabled == false ? null : _toggleOverlay,
                child: Container(
                  height: 44.0,
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  decoration: BoxDecoration(
                    color: widget.fillColor ?? AppColors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: _getBorderColor(),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppText.styledBodyMedium(
                          context,
                          displayText != null
                              ? (displayText is Text
                                  ? displayText.data ?? ''
                                  : widget.value.toString())
                              : widget.hintText ?? 'Select...',
                          color: displayText != null
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                      Icon(
                        _isOverlayOpen
                            ? Icons.arrow_drop_up
                            : Icons.arrow_drop_down,
                        color: widget.enabled == false
                            ? AppColors.textMuted
                            : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Error or helper text
          if (widget.errorText != null) ...[
            const SizedBox(height: 4.0),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: AppText.styledBodySmall(
                context,
                widget.errorText!,
                color: AppColors.inputError,
              ),
            ),
          ] else if (widget.helperText != null) ...[
            const SizedBox(height: 4.0),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: AppText.styledBodySmall(
                context,
                widget.helperText!,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStandardDropdown() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: widget.width ?? 360.0,
        // Remove minHeight constraint to allow proper expansion for helper/error text
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
          // Dropdown field
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
                // Remove helperText and errorText from InputDecoration - render them separately
                helperText: null,
                errorText: null,
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
          // Render helper text or error text separately below the dropdown
          if (widget.errorText != null) ...[
            const SizedBox(height: 4.0),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: AppText.styledBodySmall(
                context,
                widget.errorText!,
                color: AppColors.inputError,
              ),
            ),
          ] else if (widget.helperText != null) ...[
            const SizedBox(height: 4.0),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: AppText.styledBodySmall(
                context,
                widget.helperText!,
                color: AppColors.textMuted,
              ),
            ),
          ],
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
