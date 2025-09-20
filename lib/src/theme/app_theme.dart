import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.orange,
  scaffoldBackgroundColor: Colors.grey[100],
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[100],
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
    titleTextStyle: GoogleFonts.inter(
      color: Colors.black,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.light().textTheme,
  ),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    secondary: Colors.orange,
    primary: Colors.orange,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.orange,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.orange,
  scaffoldBackgroundColor: Colors.grey[900],
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[900],
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.white),
    titleTextStyle: GoogleFonts.inter(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
  textTheme: GoogleFonts.interTextTheme(
    ThemeData.dark().textTheme,
  ),
  colorScheme: ColorScheme.fromSwatch(
    brightness: Brightness.dark,
  ).copyWith(
    secondary: Colors.orange,
    primary: Colors.orange,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: Colors.orange,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.orange,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
);
