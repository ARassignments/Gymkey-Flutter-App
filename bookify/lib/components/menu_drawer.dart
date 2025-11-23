import 'dart:ui';
import '/managers/cart_manager.dart';
import '/managers/wishlist_manager.dart';
import '/models/cart_item.dart';
import '/screens/auth/users/sign_in.dart';
import '/utils/themes/themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:shimmer/shimmer.dart';
import '/components/dialog_logout.dart';

class MenuDrawer extends StatefulWidget {
  final Function(int) onItemSelected;
  final int currentIndex;
  final bool? forAdmin;

  const MenuDrawer({
    super.key,
    required this.onItemSelected,
    required this.currentIndex,
    this.forAdmin,
  });

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<Offset>> _slideAnimations;
  late List<Animation<double>> _fadeAnimations;
  late List<String> menus;
  late List<List<IconData>> icons;

  @override
  void initState() {
    super.initState();
    if (widget.forAdmin == true) {
      menus = [
        "Home",
        "Manage Categories",
        "Manage Products",
        "Manage Orders",
        "Profile",
      ];

      icons = [
        [HugeIconsStroke.home11, HugeIconsSolid.home11],
        [HugeIconsStroke.catalogue, HugeIconsSolid.catalogue],
        [HugeIconsStroke.deliveryBox01, HugeIconsSolid.deliveryBox01],
        [HugeIconsStroke.shoppingBag02, HugeIconsSolid.shoppingBag02],
        [HugeIconsStroke.user03, HugeIconsSolid.user03],
      ];
    } else {
      menus = ["Home", "Catalogs", "Cart", "Wishlist", "Accounts"];

      icons = [
        [HugeIconsStroke.home11, HugeIconsSolid.home11],
        [HugeIconsStroke.catalogue, HugeIconsSolid.catalogue],
        [HugeIconsStroke.shoppingCart01, HugeIconsSolid.shoppingCart01],
        [HugeIconsStroke.favourite, HugeIconsSolid.favourite],
        [HugeIconsStroke.user03, HugeIconsSolid.user03],
        [HugeIconsStroke.userGroup, HugeIconsSolid.userGroup],
        [HugeIconsStroke.moneyReceiveFlow01, HugeIconsSolid.moneyReceiveFlow01],
        [HugeIconsStroke.recycle02, HugeIconsSolid.recycle02],
      ];
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _slideAnimations = List.generate(
      menus.length,
      (i) =>
          Tween<Offset>(begin: const Offset(-1.0, 0), end: Offset.zero).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(i * 0.1, 1.0, curve: Curves.easeOut),
            ),
          ),
    );

    _fadeAnimations = List.generate(
      menus.length,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(i * 0.1, 1.0, curve: Curves.easeIn),
        ),
      ),
    );
  }

  void _logout() {
    final auth = FirebaseAuth.instance;
    if (mounted) {
      auth.signOut().then((_) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => SignIn(),
            transitionsBuilder: (_, a, __, c) =>
                FadeTransition(opacity: a, child: c),
          ),
        );
      });
    }
  }

  Widget buildMenuBadge(int count) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardDarkBg(context),
        shape: BoxShape.circle,
      ),
      child: Text(
        count.toString().padLeft(2, '0'),
        style: AppTheme.textSearchInfoLabeled(context).copyWith(fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          // child: Container(color: AppTheme.customListBg(context).withOpacity(1.0)),
        ),

        StreamBuilder<List<CartItem>>(
          stream: CartManager.getCartStream(),
          builder: (context, cartSnap) {
            int cartCount = cartSnap.data?.length ?? 0;

            return StreamBuilder<List<CartItem>>(
              stream: WishlistManager.getWishlistStream(),
              builder: (context, wishSnap) {
                int wishlistCount = wishSnap.data?.length ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    top: 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            AppTheme.appLogo(context),
                            height: 120,
                            width: 60,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "My",
                            style: AppTheme.textTitle(context).copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            "Dashboard",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.textTitle(context).copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                          Text(
                            ".",
                            style: AppTheme.textTitleActive(
                              context,
                            ).copyWith(fontSize: 30),
                          ),
                        ],
                      ),
                      // const SizedBox(height: 10),
                      ...List.generate(menus.length, (index) {
                        bool isActive = index == widget.currentIndex;
                        return SlideTransition(
                          position: _slideAnimations[index],
                          child: FadeTransition(
                            opacity: _fadeAnimations[index],
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 600),
                              // margin: const EdgeInsets.only(bottom: 5),
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 15,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppTheme.customListBg(context)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InkWell(
                                onTap: () {
                                  if (index <= 4) {
                                    widget.onItemSelected(index);
                                  } else {
                                    // switch (index) {
                                    //   case 4:
                                    //     Navigator.push(
                                    //       context,
                                    //       MaterialPageRoute(
                                    //         builder: (_) => const CustomersScreen(),
                                    //       ),
                                    //     );
                                    //     break;
                                    //   case 5:
                                    //     Navigator.push(
                                    //       context,
                                    //       MaterialPageRoute(
                                    //         builder: (_) => const PaymentsScreen(),
                                    //       ),
                                    //     );
                                    //     break;
                                    //   case 6:
                                    //     Navigator.push(
                                    //       context,
                                    //       MaterialPageRoute(
                                    //         builder: (_) => const ScrapsScreen(),
                                    //       ),
                                    //     );
                                    //     break;
                                    // }
                                  }
                                },
                                child: Row(
                                  spacing: 16,
                                  children: [
                                    Icon(
                                      isActive
                                          ? icons[index][1]
                                          : icons[index][0],
                                      color: isActive
                                          ? AppTheme.iconColor(context)
                                          : AppTheme.iconColorThree(context),
                                    ),
                                    Text(
                                      menus[index],
                                      style: AppTheme.textLabel(context)
                                          .copyWith(
                                            fontWeight: isActive
                                                ? FontWeight.w500
                                                : FontWeight.w300,
                                          ),
                                    ),
                                    Spacer(),
                                    if (menus[index] == "Cart" && cartCount > 0)
                                      buildMenuBadge(cartCount),

                                    if (menus[index] == "Wishlist" &&
                                        wishlistCount > 0)
                                      buildMenuBadge(wishlistCount),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      // Divider(color: AppTheme.dividerBg(context)),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColor.accent_50),
                          overlayColor: AppColor.accent_50.withOpacity(0.1),
                        ),
                        child: Text(
                          'Log Out',
                          style: TextStyle(color: AppColor.accent_50),
                        ),
                        onPressed: () {
                          DialogLogout().showDialog(context, _logout);
                        },
                      ),
                      const SizedBox(height: 20),
                      Shimmer(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.sliderHighlightBg(context),
                            AppTheme.iconColorThree(context),
                            AppTheme.sliderHighlightBg(context),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        direction: ShimmerDirection.rtl,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 12,
                          children: [
                            const Icon(HugeIconsStroke.swipeLeft01),
                            Text(
                              "Swipe left to close menu",
                              style: AppTheme.textLink(context).copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
