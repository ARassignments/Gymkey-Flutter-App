import 'package:bookify/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';

import '/screens/profile.dart';
import '/utils/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '/screens/home.dart';
import '/screens/catalog.dart';
import '/screens/cart.dart';
import '/screens/wishlist.dart';

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
Widget buildCurvedNavBar(BuildContext context, int currentIndex) {
  return CurvedNavigationBar(
    index: currentIndex,
    height: 50,
    backgroundColor: AppTheme.screenBg(context),
    color: MyColors.primary,
    buttonBackgroundColor: MyColors.primary,
    animationDuration: const Duration(milliseconds: 300),
    animationCurve: Curves.easeInOut,
    items: const [
      Icon(HugeIconsSolid.home09, size: 30, color: Colors.white),
      Icon(HugeIconsSolid.catalogue, size: 30, color: Colors.white),
      Icon(HugeIconsSolid.shoppingCart01, size: 30, color: Colors.white),
      Icon(HugeIconsSolid.favourite, size: 30, color: Colors.white),
      Icon(HugeIconsSolid.user03, size: 30, color: Colors.white),
    ],
    onTap: (index) async {
      if (index == currentIndex) return;

      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // slight delay for nav bar animation

      switch (index) {
        case 0:
          navigateWithFade(context, const HomeScreen());
          break;
        case 1:
          navigateWithFade(context, const CatalogScreen());
          break;
        case 2:
          navigateWithFade(context, const CartScreen());
          break;
        case 3:
          navigateWithFade(context, const WishListScreen());
          break;
        case 4:
          navigateWithFade(context, const ProfileScreen());
          break;
      }
    },
  );
}
