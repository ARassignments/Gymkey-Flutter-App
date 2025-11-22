import '/utils/themes/themes.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

/// Curved Navigation Bar builder
Widget buildAdminCurvedNavBar(
  BuildContext context,
  int currentIndex,
  Function(int) onItemSelected,
) {
  return CurvedNavigationBar(
    index: currentIndex,
    height: 65,
    backgroundColor: AppTheme.screenBg(context),
    color: AppTheme.navbarBg(context),
    buttonBackgroundColor: AppTheme.navbarBg(context),
    animationDuration: const Duration(milliseconds: 300),
    animationCurve: Curves.easeInOut,

    items: [
      const Icon(HugeIconsSolid.home11, size: 30, color: Colors.white),
      const Icon(HugeIconsSolid.catalogue, size: 30, color: Colors.white),
      const Icon(HugeIconsSolid.deliveryBox01, size: 30, color: Colors.white),
      const Icon(HugeIconsSolid.shoppingBag02, size: 30, color: Colors.white),
      const Icon(HugeIconsSolid.user03, size: 30, color: Colors.white),
    ],

    onTap: (index) {
      if (index == currentIndex) return;
      onItemSelected(index);
    },
  );

}

Widget buildBadgeIcon(
  BuildContext context, {
  required IconData icon,
  required int count,
  Color iconColor = Colors.white,
  double size = 26,
}) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      Padding(
        padding: EdgeInsets.all(3),
        child: Icon(icon, size: count > 0 ? 26 : size, color: iconColor),
      ),

      if (count > 0)
        Positioned(
          right: -12,
          top: -12,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 850),
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppTheme.sliderHighlightBg(context),
              shape: BoxShape.circle,
            ),
            child: Text(
              count.toString().padLeft(2, '0'),
              style: AppTheme.textTitle(context).copyWith(fontSize: 8),
            ),
          ),
        ),
    ],
  );
}
