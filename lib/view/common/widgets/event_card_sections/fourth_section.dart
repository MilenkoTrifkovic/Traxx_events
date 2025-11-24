import 'package:flutter/material.dart';
import 'package:traxx_wepapp/models/event.dart';

class FourthSection extends StatelessWidget {
  final Event event;

  const FourthSection({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: const Center(
        child: Text(
          'Fourth Section Placeholder',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
