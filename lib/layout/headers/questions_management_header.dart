import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuestionsManagementHeader extends StatelessWidget {
  const QuestionsManagementHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final titleSize = w < 600 ? 26.0 : (w < 1200 ? 32.0 : 40.0);

    return Text(
      'Demographic Questions',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.poppins(
        fontSize: titleSize,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
    );
  }
}
