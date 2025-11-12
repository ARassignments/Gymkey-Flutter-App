import '/theme/theme.dart';
import 'package:flutter/material.dart';
import '/utils/constants/colors.dart';

class MyTextFormFieldTheme {
  MyTextFormFieldTheme._();

  static final lightInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColor.neutral_5,
    hoverColor: AppColor.transparent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    errorMaxLines: 3,
    prefixIconColor: AppColor.neutral_20,
    suffixIconColor: AppColor.neutral_20,
    labelStyle: const TextStyle(fontSize: 14, color: AppColor.neutral_40),
    hintStyle: const TextStyle(fontSize: 14, color: AppColor.neutral_40),
    errorStyle: const TextStyle(fontStyle: FontStyle.normal, color: Colors.red),
    iconColor: AppColor.neutral_10,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: AppColor.neutral_20,
        width: 1,
      ),
    ),
    floatingLabelStyle: const TextStyle(
      fontSize: 14,
      color: MyColors.primary,
      fontWeight: FontWeight.w500,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(width: 1, color: MyColors.primary),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(width: 2, color: MyColors.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2, color: Colors.orange),
    ),
  );

  // darkInputDecorationTheme remains same as before

  static final darkInputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColor.neutral_90,
    hoverColor: AppColor.transparent,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    errorMaxLines: 3,
    prefixIconColor: AppColor.neutral_20,
    suffixIconColor: AppColor.neutral_20,
    labelStyle: const TextStyle(fontSize: 14, color: AppColor.neutral_40),
    hintStyle: const TextStyle(fontSize: 14, color: AppColor.neutral_40),
    errorStyle: const TextStyle(fontStyle: FontStyle.normal, color: Colors.red),
    iconColor: AppColor.neutral_10,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: AppColor.neutral_20,
        width: 1,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.white54),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2, color: MyColors.primary),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 1, color: Colors.red),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(width: 2, color: Colors.orange),
    ),
  );
}
