import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const appName = 'Expense Tracker'; // working name: change it here later

class C {
  static const mint = Color(0xFF58B380);
  static const forest = Color(0xFF1E4A36);
  static const forestMid = Color(0xFF2D6A4F);
  static const forestDark = Color(0xFF173B2B);
  static const black = Color(0xFF000000);
  static const grey = Color(0xFFF2F2F2);
  static const text2 = Color(0xFF4A4A4A);
  static const lightGreen = Color(0xFFB9D4C5);
  static const tint = Color(0xFFDCEFE4);
  static const danger = Color(0xFFB42318);
}

TextStyle serif(double size, {Color color = Colors.black}) => GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.15,
      letterSpacing: -0.5,
    );

TextStyle sans(double size,
        {FontWeight w = FontWeight.w500, Color color = Colors.black}) =>
    GoogleFonts.dmSans(fontSize: size, fontWeight: w, color: color);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(
      primary: C.forest,
      onPrimary: Colors.white,
      secondary: C.mint,
      surface: Colors.white,
    ),
  );
  return base;
}
