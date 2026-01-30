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
  late final ScrollController _h;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _h = ScrollController();

    // ✅ wait one frame so the controller definitely gets a ScrollPosition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _h.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scrollView = SingleChildScrollView(
      controller: _h,
      primary: false,
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: widget.minWidth),
        child: widget.child,
      ),
    );

    // ✅ Avoid first-frame “no ScrollPosition attached” on web
    if (!_ready) return scrollView;

    return Scrollbar(
      controller: _h,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: scrollView,
    );
  }
}
