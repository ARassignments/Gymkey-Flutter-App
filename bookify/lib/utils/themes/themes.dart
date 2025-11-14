import 'package:bookify/utils/constants/colors.dart';
import 'package:bookify/utils/themes/custom_themes/appbar_theme.dart';
import 'package:bookify/utils/themes/custom_themes/bottom_sheet_theme.dart';
import 'package:bookify/utils/themes/custom_themes/checkbox_theme.dart';
import 'package:bookify/utils/themes/custom_themes/chip_theme.dart';
import 'package:bookify/utils/themes/custom_themes/elevated_button_theme.dart';
import 'package:bookify/utils/themes/custom_themes/outlined_button_theme.dart';
import 'package:bookify/utils/themes/custom_themes/text_field_theme.dart';
import 'package:bookify/utils/themes/custom_themes/text_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController {
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.system,
  );
  static const String _key = "theme_mode";

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_key);
    if (themeIndex != null && themeIndex < ThemeMode.values.length) {
      themeNotifier.value = ThemeMode.values[themeIndex];
    } else {
      themeNotifier.value = ThemeMode.system;
    }
  }

  static Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
    themeNotifier.value = mode;
  }
}

class AppColor {
  // Basic Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0xff00ffffff);

  // Primary Colors
  static const Color primary_5 = Color(0xFFF3F1FE);
  static const Color primary_10 = Color(0xFFDDD7FC);
  static const Color primary_20 = Color(0xFFBBB1FA);
  static const Color primary_30 = Color(0xFF9487F1);
  static const Color primary_40 = Color(0xFF7466E3);
  static const Color primary_50 = Color(0xFF4838D1);
  static const Color primary_60 = Color(0xFF3528B3);
  static const Color primary_70 = Color(0xFF261C96);
  static const Color primary_80 = Color(0xFF191179);
  static const Color primary_90 = Color(0xFF100A64);
  static const Color primary_100 = Color(0xFF090638);

  // Accent Colors
  static const Color accent_5 = Color(0xFFFFFAF5);
  static const Color accent_10 = Color(0xFFFEEEDD);
  static const Color accent_20 = Color(0xFFFED9BB);
  static const Color accent_30 = Color(0xFFFCBE99);
  static const Color accent_40 = Color(0xFFFAA47F);
  static const Color accent_50 = Color(0xFFF77A55);
  static const Color accent_60 = Color(0xFFD4553E);
  static const Color accent_70 = Color(0xFFB1362A);
  static const Color accent_80 = Color(0xFF8F1C1B);
  static const Color accent_90 = Color(0xFF761016);
  static const Color accent_100 = Color(0xFF480A0D);

  // Neutral Colors
  static const Color neutral_5 = Color(0xFFF5F5FA);
  static const Color neutral_10 = Color(0xFFEBEBF5);
  static const Color neutral_20 = Color(0xFFD5D5E3);
  static const Color neutral_30 = Color(0xFFB8B8C7);
  static const Color neutral_40 = Color(0xFFB8B8C7);
  static const Color neutral_50 = Color(0xFF9292A2);
  static const Color neutral_60 = Color(0xFF6A6A8B);
  static const Color neutral_70 = Color(0xFF494974);
  static const Color neutral_80 = Color(0xFF2E2E5D);
  static const Color neutral_90 = Color(0xFF1C1C4D);
  static const Color neutral_100 = Color(0xFF0F0F29);
}

class AppTheme {
  static Color screenBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColor.neutral_100
        : AppColor.white;
  }

  static Color customListBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColor.neutral_90
        : AppColor.neutral_5;
  }
  
  static Color navbarBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColor.neutral_90
        : MyColors.primary;
  }

  static String appLogo(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? 'assets/images/logo_dark.png'
        : 'assets/images/logo222.png';
  }

  static String notFoundImage(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? 'assets/images/not_found_frame_dark.svg'
        : 'assets/images/not_found_frame.svg';
  }

  static Color checkBox(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColor.white
      : AppColor.black;

  static Color onBoardingDot(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColor.white.withOpacity(0.5)
      : AppColor.black.withOpacity(0.5);

  static Color onBoardingDotActive(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColor.white
      : AppColor.black;

  static Color inputProgress(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColor.neutral_60
      : AppColor.neutral_80;

  static Color dividerBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColor.neutral_80
      : AppColor.neutral_10;

  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColor.neutral_90.withOpacity(0.4)
      : AppColor.neutral_5;

  static Color cardDarkBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColor.neutral_100
      : AppColor.white;

  static Color sliderHighlightBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColor.neutral_80
      : AppColor.white;

  static Color iconColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColor.white
      : AppColor.neutral_80;

  static Color iconColorTwo(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColor.neutral_50
      : AppColor.neutral_60;

  static Color iconColorThree(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? AppColor.neutral_50
      : AppColor.neutral_30;

  static TextStyle textLink(BuildContext context) => TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 14,
    color: Theme.of(context).brightness == Brightness.dark
        ? AppColor.white
        : AppColor.neutral_80,
  );

  static TextStyle textLabel(BuildContext context) {
    return TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 14,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColor.white
          : AppColor.neutral_80,
    );
  }

  static TextStyle textTitle(BuildContext context) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColor.white
          : AppColor.neutral_80,
    );
  }

  static TextStyle textTitleActive(BuildContext context) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColor.white
          : AppColor.accent_50,
    );
  }

  static TextStyle textTitleActiveTwo(BuildContext context) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 16,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColor.white
          : AppColor.primary_50,
    );
  }

  static TextStyle textSearchInfo(BuildContext context) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 10,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColor.neutral_70
          : AppColor.neutral_40,
    );
  }

  static TextStyle textSearchInfoLabeled(BuildContext context) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 10,
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColor.neutral_50
          : AppColor.neutral_60,
    );
  }

  static BoxDecoration dialogBg(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColor.neutral_100
          : AppColor.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColor.neutral_80.withOpacity(0.2)
              : AppColor.neutral_20.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

class MyTheme {
  MyTheme._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    hoverColor: Colors.transparent,
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: Colors.white,
    textTheme: MyTextTheme.lightTextTheme,
    elevatedButtonTheme: MyElevatedButtonTheme.lightElevatedButtonTheme,
    appBarTheme: MyAppBarTheme.lightAppBarTheme,
    bottomSheetTheme: MyBottomSheetTheme.lightBottomSheetTheme,
    checkboxTheme: MyCheckboxTheme.lightCheckboxTheme,
    chipTheme: MyChipTheme.lightChipTheme,
    outlinedButtonTheme: MyOutlinedButtonTheme.lightOutlinedButtonTheme,
    inputDecorationTheme: MyTextFormFieldTheme.lightInputDecorationTheme,
  );
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    hoverColor: Colors.transparent,
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: Colors.blue,
    scaffoldBackgroundColor: AppColor.neutral_100,
    textTheme: MyTextTheme.darkTextTheme,
    elevatedButtonTheme: MyElevatedButtonTheme.darkElevatedButtonTheme,
    appBarTheme: MyAppBarTheme.darkAppBarTheme,
    bottomSheetTheme: MyBottomSheetTheme.darkBottomSheetTheme,
    checkboxTheme: MyCheckboxTheme.darkCheckboxTheme,
    chipTheme: MyChipTheme.darkkChipTheme,
    outlinedButtonTheme: MyOutlinedButtonTheme.darkOutlinedButtonTheme,
    inputDecorationTheme: MyTextFormFieldTheme.lightInputDecorationTheme,
  );
}
