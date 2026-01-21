import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CalenderTextHeader extends StatelessWidget {
  const CalenderTextHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = w < 600 ? 26.0 : (w < 1200 ? 32.0 : 40.0);

    final isMobile = w < 600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Calender',
            style: GoogleFonts.poppins(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
            )),
      ],
    );
  }
}
