import '/utils/themes/themes.dart';
import 'package:flutter/material.dart';
import '/utils/constants/colors.dart';

class MyTextFormFieldTheme {
  MyTextFormFieldTheme._();

  static final darkInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColor.neutral_90,
    hoverColor: AppColor.transparent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    errorMaxLines: 3,
    prefixIconColor: AppColor.neutral_70,
    suffixIconColor: AppColor.neutral_70,
    labelStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: AppColor.neutral_60,
    ),
    hintStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: AppColor.neutral_60,
    ),
    helperStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 10,
      color: AppColor.neutral_60,
    ),
    counterStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 10,
      color: AppColor.neutral_60,
    ),
    errorStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 10,
      fontStyle: FontStyle.normal,
      color: AppColor.neutral_40,
    ),
    iconColor: AppColor.neutral_70,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColor.neutral_80, width: 1),
    ),
    floatingLabelStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      // color: MyColors.primary,
      fontWeight: FontWeight.w500,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(width: 1, color: AppColor.transparent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(width: 1, color: AppColor.neutral_80),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(width: 1, color: AppColor.neutral_60),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(width: 1, color: AppColor.neutral_60),
    ),
  );

  // darkInputDecorationTheme remains same as before

  static final lightInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColor.neutral_5,
    hoverColor: AppColor.transparent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    errorMaxLines: 3,
    prefixIconColor: AppColor.neutral_20,
    suffixIconColor: AppColor.neutral_20,
    labelStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: AppColor.neutral_40,
    ),
    hintStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: AppColor.neutral_40,
    ),
    helperStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 10,
      color: AppColor.neutral_40,
    ),
    counterStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 10,
      color: AppColor.neutral_40,
    ),
    errorStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 10,
      fontStyle: FontStyle.normal,
      color: AppColor.black,
    ),
    iconColor: AppColor.neutral_10,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColor.neutral_20, width: 1),
    ),
    floatingLabelStyle: const TextStyle(
      fontFamily: 'Poppins',
      fontSize: 14,
      color: MyColors.primary,
      fontWeight: FontWeight.w500,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(width: 1, color: AppColor.transparent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(width: 1, color: AppColor.neutral_20),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(width: 1, color: AppColor.black),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(width: 1, color: AppColor.black),
    ),
  );
}
