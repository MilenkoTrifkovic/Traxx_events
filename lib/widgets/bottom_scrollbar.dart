import 'package:flutter/material.dart';

class BottomHScrollbar extends StatefulWidget {
  final Widget child;
  final double minWidth;

  const BottomHScrollbar({
    super.key,
    required this.child,
    required this.minWidth,
  });

  @override
  State<BottomHScrollbar> createState() => _BottomHScrollbarState();
}

class _BottomHScrollbarState extends State<BottomHScrollbar> {
  final ScrollController _h = ScrollController();

  @override
  void dispose() {
    _h.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _h,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        controller: _h,
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: widget.minWidth),
          child: widget.child,
        ),
      ),
    );
  }
}
