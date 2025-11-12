import 'package:bookify/screens/admin/screens/dashboard.dart';
import 'package:bookify/screens/admin/screens/manage_books/manage_books.dart';
import 'package:bookify/screens/admin/screens/manage_orders/manage_orders.dart';
import 'package:bookify/screens/admin/screens/manage_users/manage_users.dart';
import 'package:bookify/utils/constants/colors.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

/// Smooth fade transition navigation
void navigateWithFade(BuildContext context, Widget targetPage) {
  Navigator.of(context).pushReplacement(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) => targetPage,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    ),
  );
}

/// Curved Navigation Bar builder
Widget buildAdminCurvedNavBar(BuildContext context, int currentIndex) {
  return CurvedNavigationBar(
    index: currentIndex,
    height: 60,
    backgroundColor: const Color(0xFFeeeeee),
    color: MyColors.primary,
    buttonBackgroundColor: Color.fromARGB(255, 10, 129, 234),
    animationDuration: const Duration(milliseconds: 600),
    animationCurve: Curves.easeInOut,
    items: const [
      Icon(Icons.dashboard, size: 30, color: Colors.white),
      Icon(Icons.book, size: 30, color: Colors.white),
      Icon(Icons.people, size: 30, color: Colors.white),
      Icon(Icons.shopping_cart, size: 30, color: Colors.white),
    ],
    onTap: (index) async {
      if (index == currentIndex) return;

      await Future.delayed(
        const Duration(milliseconds: 300),
      ); // slight delay for nav bar animation

      switch (index) {
        case 0:
          navigateWithFade(context, const Dashboard());
          break;
        case 1:
          navigateWithFade(context, const ManageBooks());
          break;
        case 2:
          navigateWithFade(context, const ManageUsers());
          break;
        case 3:
          navigateWithFade(context, const ManageOrders());
          break;
      }
    },
  );
}
