import '/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import '/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

/// Smooth fade transition navigation
void navigateWithFade(BuildContext context, Widget targetPage) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 100),
      pageBuilder: (context, animation, secondaryAnimation) => targetPage,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

/// Curved Navigation Bar builder
Widget buildCurvedNavBar(BuildContext context, int currentIndex, Function(int) onItemSelected) {
  return CurvedNavigationBar(
    index: currentIndex,
    height: 50,
    backgroundColor: AppTheme.screenBg(context),
    color: MyColors.primary,
    buttonBackgroundColor: MyColors.primary,
    animationDuration: const Duration(milliseconds: 300),
    animationCurve: Curves.easeInOut,
    items: const [
      Icon(HugeIconsSolid.home11, size: 30, color: Colors.white),
      Icon(HugeIconsSolid.catalogue, size: 30, color: Colors.white),
      Icon(HugeIconsSolid.shoppingCart01, size: 30, color: Colors.white),
      Icon(HugeIconsSolid.favourite, size: 30, color: Colors.white),
      Icon(HugeIconsSolid.user03, size: 30, color: Colors.white),
    ],
    onTap: (index) {
      if (index == currentIndex) return;

      // await Future.delayed(
      //   const Duration(milliseconds: 200),
      // ); // slight delay for nav bar animation

      onItemSelected(index);
    },
  );
}
