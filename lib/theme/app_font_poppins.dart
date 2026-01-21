import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PoppinsTheme extends StatelessWidget {
  final Widget child;
  const PoppinsTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    return Theme(
      data: base.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(base.textTheme),
        primaryTextTheme: GoogleFonts.poppinsTextTheme(base.primaryTextTheme),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          labelStyle: GoogleFonts.poppins(),
          hintStyle: GoogleFonts.poppins(),
          floatingLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      child: DefaultTextStyle(
        style: GoogleFonts.poppins(),
        child: child,
      ),
    );
  }
}
