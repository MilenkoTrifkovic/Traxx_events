import 'package:flutter/material.dart';
import 'package:traxx_wepapp/models/menu_item.dart';
import 'package:traxx_wepapp/widgets/app_search_input_field.dart';

class SearchableDropdownOverlay extends StatefulWidget {
  final List<dynamic> items; // original list
  final String Function(dynamic item)
      searchKey; // how to convert item to string
  final Widget Function(dynamic item) itemBuilder;
  final void Function(MenuItem item) onItemTap;
  final double maxHeight;

  const SearchableDropdownOverlay({
    super.key,
    required this.items,
    required this.searchKey,
    required this.itemBuilder,
    required this.onItemTap,
    this.maxHeight = 260,
  });

  @override
  State<SearchableDropdownOverlay> createState() =>
      _SearchableDropdownOverlayState();
}

class _SearchableDropdownOverlayState extends State<SearchableDropdownOverlay> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _controller = TextEditingController();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  List<dynamic> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _openOverlay() {
    _overlayEntry = _createOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (!mounted) return;
    setState(() => _isOpen = false);
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeOverlay();
    } else {
      _openOverlay();
    }
  }

  void _filterItems(String query) {
    setState(() {
      _filteredItems = widget.items
          .where((item) => widget
              .searchKey(item)
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });

    if (!_isOpen) _openOverlay();
    _overlayEntry?.markNeedsBuild();
  }

  OverlayEntry _createOverlay() {
    RenderBox box = context.findRenderObject() as RenderBox;
    final size = box.size;

    return OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            offset: Offset(0, size.height + 4),
            showWhenUnlinked: false,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: widget.maxHeight,
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: _filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = _filteredItems[index];

                    return InkWell(
                      onTap: () {
                        widget.onItemTap(item);
                        _closeOverlay();
                      },
                      child: widget.itemBuilder(item),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
        link: _layerLink,
        child: AppSearchInputField(
          controller: _controller,
          onTap: _toggleDropdown,
          onChanged: _filterItems, // ← filtering while typing!
          hintText: "Search...",
          suffixIcon: Icon(
            _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
          ),
        )
        // child: TextField(
        //   controller: _controller,
        //   onTap: _toggleDropdown,
        //   onChanged: _filterItems, // ← filtering while typing!
        //   decoration: InputDecoration(
        //     hintText: "Search...",
        //     suffixIcon: Icon(
        //       _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
        //     ),
        //     border: OutlineInputBorder(
        //       borderRadius: BorderRadius.circular(8),
        //     ),
        //   ),
        // ),
        );
  }
}
