import 'package:flutter/material.dart';

class MyOutlinedButtonTheme {
  MyOutlinedButtonTheme._();

  static final lightOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: Colors.black,
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: Colors.black),
      textStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.black,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );

  static final darkOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      elevation: 0,
      foregroundColor: Colors.white,
      backgroundColor: Colors.transparent,
      side: const BorderSide(color: Colors.white),
      textStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
